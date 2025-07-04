import asyncio
import json
import logging
import os
import cv2
import numpy as np
import websockets
import mediapipe as mp
import pygame
from scipy.spatial import distance as dist
import time

# Initialize logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# ====== CONFIGURATION ======
HOST = '0.0.0.0'  # Listen on all network interfaces
PORT = 65486
ALERTS_FOLDER = "dms_alerts"
os.makedirs(ALERTS_FOLDER, exist_ok=True)

# Initialize pygame for sound
try:
    pygame.mixer.init()
    alert_sound = pygame.mixer.Sound("alert_beep.wav")
except Exception as e:
    logger.warning(f"Could not initialize sound: {e}")
    def play_alert():
        logger.info("ALERT: Drowsiness detected!")
else:
    def play_alert():
        try:
            alert_sound.play()
        except Exception as e:
            logger.error(f"Error playing alert sound: {e}"
        os.system(f'powershell -c (New-Object System.Media.SoundPlayer).PlaySync(); [console]::beep({freq},{duration * 1000})')

# ====== DETECTION PARAMETERS ======
YAWN_THRESHOLD = 0.37
YAWN_MIN_DURATION = 1.0

EYE_AR_THRESH = 0.25
EYE_AR_CONSEC_FRAMES = 20

LOOK_LEFT_THRESHOLD = -25
LOOK_RIGHT_THRESHOLD = 25
ALERT_FRAMES_REQUIRED = 20
head_turn_counter = 0
yaw_history = []
SMOOTHING_WINDOW = 10
NEUTRAL_ZONE = 20
ALERT_DURATION = 3

def eye_aspect_ratio(eye):
    A = np.linalg.norm(np.array(eye[1]) - np.array(eye[5]))
    B = np.linalg.norm(np.array(eye[2]) - np.array(eye[4]))
    C = np.linalg.norm(np.array(eye[0]) - np.array(eye[3]))
    return (A + B) / (2.0 * C)

def detect_yawn(mouth_landmarks):
    top_lip = np.array(mouth_landmarks[0])
    bottom_lip = np.array(mouth_landmarks[1])
    distance = np.linalg.norm(top_lip - bottom_lip)
    return distance

def play_alert_sound():
    try:
        alert_sound.play()
        pygame.time.wait(1000)
    except:    play_alert()

def save_alert_screenshot(frame, alert_type):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    screenshot_path = os.path.join(ALERTS_FOLDER, f"{alert_type}_alert_{timestamp}.jpg")
    cv2.imwrite(screenshot_path, frame)

def estimate_head_pose(landmarks, frame_width):
    left_eye = landmarks[33]
    right_eye = landmarks[263]
    face_center = (left_eye[0] + right_eye[0]) // 2
    return (face_center - frame_width//2) / (frame_width//2) * 100

def process_frame(frame):
    try:
        mp_face_mesh = mp.solutions.face_mesh
        face_mesh = mp_face_mesh.FaceMesh(static_image_mode=False, max_num_faces=1, refine_landmarks=True)
        
        frame_width = frame.shape[1]
        frame_height = frame.shape[0]
        
        results = face_mesh.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        if results.multi_face_landmarks:
            for face_landmarks in results.multi_face_landmarks:
                landmarks = [(int(lm.x * frame_width), int(lm.y * frame_height)) for lm in face_landmarks.landmark]

                # Yawn Detection
                mouth_open_dist = detect_yawn([landmarks[13], landmarks[14]])
                mouth_ratio = mouth_open_dist / frame_height

                # Sleep Detection
                left_eye_pts = [landmarks[i] for i in [362, 385, 387, 263, 373, 380]]
                right_eye_pts = [landmarks[i] for i in [33, 160, 158, 133, 153, 144]]
                ear = (eye_aspect_ratio(left_eye_pts) + eye_aspect_ratio(right_eye_pts)) / 2.0

                # Head Pose
                yaw = estimate_head_pose(landmarks, frame_width)
                yaw_history.append(yaw)
                if len(yaw_history) > SMOOTHING_WINDOW:
                    yaw_history.pop(0)
                smooth_yaw = np.mean(yaw_history)

                return {
                    'ear': ear,
                    'mouth_ratio': mouth_ratio,
                    'yaw': smooth_yaw,
                    'frame_width': frame_width
                }
        return None
    except Exception as e:
        print(f"Error processing frame: {e}")
        return None

def start_service():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print(f"Sleep detection service listening on {HOST}:{PORT}")
        
        while True:
            conn, addr = s.accept()
            with conn:
                print(f"Connected by {addr}")
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break
                    
                    # Process frame and send results
                    frame = np.frombuffer(data, dtype=np.uint8)
                    frame = cv2.imdecode(frame, cv2.IMREAD_COLOR)
                    
                    if frame is not None:
                        results = process_frame(frame)
                        if results:
                            conn.sendall(json.dumps(results).encode())
                        else:
                            conn.sendall(json.dumps({'error': 'No face detected'}).encode())

if __name__ == "__main__":
    start_service()
