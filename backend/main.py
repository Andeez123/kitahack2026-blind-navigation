import logging
import sys

# Configure logging to be visible in Cloud Run
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    stream=sys.stdout
)
logger = logging.getLogger("vision-backend")

app = FastAPI()

@app.get("/")
async def health_check():
    logger.info("Health check requested")
    return {"status": "healthy", "service": "vision-guide-backend"}

logger.info("Starting model initialization...")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

yolo = YOLO("yolov8n.pt")
midas = torch.hub.load("intel-isl/MiDaS", "MiDaS_small")
midas.eval()

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
midas.to(device)

transforms = torch.hub.load("intel-isl/MiDaS", "transforms")
transform = transforms.small_transform

depth_per = depth_obj_det(yolo, midas, transform)
print("Models loaded successfully.")

@app.websocket("/ws/vision")
async def websocket_endpoint(websocket: WebSocket):
    logger.info("Incoming WebSocket connection request...")
    await websocket.accept()
    logger.info("WebSocket connection established successfully")
    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                image_base64 = payload.get("image")
                
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    result = depth_per.process_frame(image_bytes)
                    await websocket.send_json(result)
            except json.JSONDecodeError:
                await websocket.send_json({"status": "error", "message": "Invalid JSON"})
            except Exception as e:
                logger.error(f"Processing error: {e}")
                await websocket.send_json({"status": "error", "message": str(e)})
                
    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected")
    except Exception as e:
        logger.error(f"WebSocket lifecycle error: {e}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
