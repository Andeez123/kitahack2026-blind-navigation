from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import base64
import json
from services.obj_det import process_frame

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.websocket("/ws/vision")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("Client connected to vision WebSocket")
    try:
        while True:
            # Receive data from the client
            data = await websocket.receive_text()
            try:
                # Expecting JSON with { "image": "base64_string" }
                payload = json.loads(data)
                image_base64 = payload.get("image")
                
                if image_base64:
                    # Decode base64 to bytes
                    image_bytes = base64.b64decode(image_base64)
                    
                    # Process frame (display in cv2 window)
                    result = process_frame(image_bytes)
                    
                    # Send result back to client
                    await websocket.send_json(result)
            except json.JSONDecodeError:
                await websocket.send_json({"status": "error", "message": "Invalid JSON"})
            except Exception as e:
                await websocket.send_json({"status": "error", "message": str(e)})
                
    except WebSocketDisconnect:
        print("Client disconnected")
    except Exception as e:
        print(f"WebSocket error: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
