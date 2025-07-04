# server.py
import asyncio
import base64
import time
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
import mediapipe as mp
import uvicorn
from typing import List, Tuple, Dict, Any
from datetime import datetime, timedelta

app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for frame processing
last_processed_time = datetime.now()
frame_interval = 30  # seconds
processing_lock = asyncio.Lock()
active_connections = set()

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: Dict[str, Any]):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                print(f"Error sending message: {e}")
                self.disconnect(connection)

manager = ConnectionManager()

# Initialize MediaPipe Face Mesh
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True
)

def eye_aspect_ratio(eye_landmarks: List[Tuple[float, float]]) -> float:
    """Calculate eye aspect ratio (EAR) for drowsiness detection."""
    # Vertical distances
    A = np.linalg.norm(np.array(eye_landmarks[1]) - np.array(eye_landmarks[5]))
    B = np.linalg.norm(np.array(eye_landmarks[2]) - np.array(eye_landmarks[4]))
    # Horizontal distance
    C = np.linalg.norm(np.array(eye_landmarks[0]) - np.array(eye_landmarks[3]))
    return (A + B) / (2.0 * C)

def detect_drowsiness(landmarks, frame_shape) -> dict:
    """Detect drowsiness based on facial landmarks."""
    h, w = frame_shape[:2]
    
    # Get eye landmarks (simplified)
    left_eye = [(landmarks.landmark[i].x * w, landmarks.landmark[i].y * h) 
               for i in [33, 160, 158, 133, 153, 144]]  # Left eye landmarks
    right_eye = [(landmarks.landmark[i].x * w, landmarks.landmark[i].y * h) 
                for i in [362, 385, 387, 263, 373, 380]]  # Right eye landmarks
    
    # Calculate EAR
    left_ear = eye_aspect_ratio(left_eye)
    right_ear = eye_aspect_ratio(right_eye)
    ear = (left_ear + right_ear) / 2.0
    
    # Calculate mouth aspect ratio
    mouth_top = landmarks.landmark[13]
    mouth_bottom = landmarks.landmark[14]
    mouth_ratio = abs(mouth_top.y - mouth_bottom.y)
    
    # Determine status
    status = "drowsy" if ear < 0.25 or mouth_ratio > 0.3 else "awake"
    
    return {
        "status": status,
        "ear": float(ear),
        "mouth_ratio": float(mouth_ratio),
        "gaze_status": "looking_forward"  # Simplified for now
    }

@app.post("/detect")
async def detect_face(file: UploadFile):
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if frame is None:
            return {"error": "Could not decode image"}
            
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = face_mesh.process(frame_rgb)
        
        response = {
            "status": "awake",
            "ear": 0.3,
            "mouth_ratio": 0.0,
            "gaze_status": "looking_forward"
        }
        
        if results.multi_face_landmarks:
            response = detect_drowsiness(results.multi_face_landmarks[0], frame.shape)
            
        return response
        
    except Exception as e:
        return {"error": str(e)}

async def process_frame_periodically():
    global last_processed_time
    
    while True:
        current_time = datetime.now()
        if (current_time - last_processed_time).total_seconds() >= frame_interval:
            async with processing_lock:
                last_processed_time = current_time
                # Get the latest frame from the active clients
                # This is a placeholder - you'll need to implement frame capture from the client
                # and send it to the server via WebSocket
                pass
        await asyncio.sleep(1)  # Check every second

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(process_frame_periodically())

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Receive frame data from client
            data = await websocket.receive_bytes()
            
            # Process the frame
            nparr = np.frombuffer(data, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if frame is not None:
                # Process frame and get results
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                results = face_mesh.process(frame_rgb)
                
                response = {
                    "status": "awake",
                    "ear": 0.3,
                    "mouth_ratio": 0.0,
                    "gaze_status": "looking_forward",
                    "timestamp": datetime.now().isoformat()
                }
                
                if results.multi_face_landmarks:
                    response = detect_drowsiness(results.multi_face_landmarks[0], frame.shape)
                    response["timestamp"] = datetime.now().isoformat()
                
                # Send results back to client
                await manager.broadcast(response)
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        print(f"WebSocket error: {e}")
        manager.disconnect(websocket)

if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)