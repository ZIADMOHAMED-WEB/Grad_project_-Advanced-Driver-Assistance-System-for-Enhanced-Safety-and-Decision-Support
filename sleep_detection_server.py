import asyncio
import json
import logging
import os
import cv2
import numpy as np
import websockets
import mediapipe as mp
import pygame
from datetime import datetime

# Initialize logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# ====== CONFIGURATION ======
HOST = '0.0.0.0'  # Listen on all network interfaces
PORT = 65486
ALERTS_FOLDER = "dms_alerts"

# Initialize MediaPipe Face Mesh
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# Eye and mouth landmarks for MediaPipe
LEFT_EYE = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398]
RIGHT_EYE = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
MOUTH = [61, 291, 39, 181, 0, 17, 269, 405]

# Detection thresholds
EYE_AR_THRESH = 0.25
MOUTH_AR_THRESH = 0.37
CONSEC_FRAMES = 3

# Frame counters
COUNTER = 0
ALARM_ON = False

# Create alerts directory if it doesn't exist
os.makedirs(ALERTS_FOLDER, exist_ok=True)

# Initialize pygame for sound
try:
    pygame.mixer.init()
    alert_sound = pygame.mixer.Sound("alert_beep.wav")
    logger.info("Sound system initialized successfully")
    
    def play_alert_sound():
        try:
            alert_sound.play()
            logger.info("Played alert sound")
        except Exception as e:
            logger.error(f"Error playing alert sound: {e}")
            
except Exception as e:
    logger.warning(f"Could not initialize sound system: {e}")

    def play_alert_sound():
        logger.warning("ALERT: Drowsiness detected! (Sound file not found)")

def eye_aspect_ratio(eye):
    """Calculate eye aspect ratio for drowsiness detection."""
    A = np.linalg.norm(eye[1] - eye[5])
    B = np.linalg.norm(eye[2] - eye[4])
    C = np.linalg.norm(eye[0] - eye[3])
    ear = (A + B) / (2.0 * C)
    return ear

def mouth_aspect_ratio(mouth):
    """Calculate mouth aspect ratio for yawning detection."""
    A = np.linalg.norm(mouth[1] - mouth[7])
    B = np.linalg.norm(mouth[2] - mouth[6])
    C = np.linalg.norm(mouth[3] - mouth[5])
    D = np.linalg.norm(mouth[0] - mouth[4])
    mar = (A + B + C) / (2.0 * D)
    return mar

def save_alert_screenshot(frame, alert_type):
    """Save a screenshot when an alert is triggered."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = os.path.join(ALERTS_FOLDER, f"{alert_type}_{timestamp}.jpg")
    cv2.imwrite(filename, frame)
    logger.info(f"Saved alert screenshot: {filename}")

def process_image(frame):
    # Convert the BGR image to RGB
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    # Process the frame with MediaPipe Face Mesh
    results = face_mesh.process(rgb_frame)
    
    if results.multi_face_landmarks:
        for face_landmarks in results.multi_face_landmarks:
            # Get image dimensions
            h, w = frame.shape[:2]
            
            # Get eye landmarks
            left_eye = np.array([(face_landmarks.landmark[idx].x * w, 
                               face_landmarks.landmark[idx].y * h) 
                              for idx in LEFT_EYE])
            
            right_eye = np.array([(face_landmarks.landmark[idx].x * w, 
                                face_landmarks.landmark[idx].y * h) 
                               for idx in RIGHT_EYE])
            
            # Get mouth landmarks
            mouth = np.array([(face_landmarks.landmark[idx].x * w, 
                            face_landmarks.landmark[idx].y * h) 
                           for idx in MOUTH])
            
            # Calculate eye aspect ratio for both eyes
            left_ear = eye_aspect_ratio(left_eye)
            right_ear = eye_aspect_ratio(right_eye)
            
            # Average the eye aspect ratio
            ear = (left_ear + right_ear) / 2.0
            
            # Calculate mouth aspect ratio
            mar = mouth_aspect_ratio(mouth)
            
            # Simple head pose estimation (yaw)
            nose_x = face_landmarks.landmark[1].x  # Nose tip x-coordinate
            yaw = (nose_x - 0.5) * 90  # Rough estimation in degrees
            
            # Check for drowsiness
            is_drowsy = ear < EYE_AR_THRESH
            is_yawning = mar > MOUTH_AR_THRESH
            
            # Update drowsiness counter
            global COUNTER, ALARM_ON
            if is_drowsy:
                COUNTER += 1
                if COUNTER >= CONSEC_FRAMES and not ALARM_ON:
                    ALARM_ON = True
                    play_alert_sound()
                    save_alert_screenshot(frame, 'drowsy')
            else:
                COUNTER = 0
                ALARM_ON = False
            
            # Send results to client
            result = {
                'ear': float(ear),
                'mouth_ratio': float(mar),
                'yaw': float(yaw),
                'is_drowsy': is_drowsy,
                'is_yawning': is_yawning,
                'alarm_on': ALARM_ON,
                'timestamp': datetime.now().isoformat()
            }
            
            return result
            
    else:
        # No face detected
        return {
            'error': 'No face detected',
            'ear': 0.0,
            'mouth_ratio': 0.0,
            'yaw': 0.0,
            'is_drowsy': False,
            'is_yawning': False,
            'alarm_on': False,
            'timestamp': datetime.now().isoformat()
        }

async def process_frame(websocket):
    global COUNTER, ALARM_ON
    
    try:
        logger.info("Client connected")
        
        while True:
            try:
                # Receive frame data from client
                frame_data = await asyncio.wait_for(websocket.recv(), timeout=30.0)
                
                # Convert frame data to numpy array
                nparr = np.frombuffer(frame_data, np.uint8)
                frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                
                if frame is None or frame.size == 0:
                    logger.warning("Received empty or invalid frame")
                    continue
                    
                # Process the frame
                results = process_image(frame)
                
                # Send results back to client
                if websocket.open:
                    try:
                        await websocket.send(json.dumps(results))
                    except Exception as send_error:
                        logger.error(f"Error sending results: {send_error}")
                        break
                        
            except asyncio.TimeoutError:
                logger.warning("Connection timeout, waiting for data...")
                continue
                
            except websockets.exceptions.ConnectionClosed:
                logger.info("Client disconnected")
                break
                
            except Exception as e:
                logger.error(f"Error processing frame: {e}", exc_info=True)
                if websocket.open:
                    await websocket.send(json.dumps({
                        'error': str(e),
                        'timestamp': datetime.now().isoformat()
                    }))
                    
    except Exception as e:
        logger.error(f"Unexpected error in process_frame: {e}", exc_info=True)
        
    finally:
        logger.info("Connection closed")
        try:
            await websocket.close()
        except:
            pass

async def start_server():
    async def handler(websocket, path):
        await process_frame(websocket)
        
    server = await websockets.serve(
        handler,
        HOST,
        PORT,
        max_size=10 * 1024 * 1024  # 10MB max message size
    )
    
    logger.info(f"Sleep detection service started on ws://{HOST}:{PORT}")
    await server.wait_closed()

if __name__ == "__main__":
    logger.info("Starting sleep detection service...")
    asyncio.run(start_server())
