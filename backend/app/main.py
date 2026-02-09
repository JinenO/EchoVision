from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from app.radio_transcriber import transcribe_radio_stream

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "online", "message": "EchoVision AI Server is Ready"}

# --- WEBSOCKET ENDPOINT ---
# Flutter will connect to this URL: ws://YOUR_IP:8000/ws/radio
@app.websocket("/ws/radio")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("📱 Client connected to WebSocket")
    
    try:
        # 1. Wait for Flutter to send the Radio URL
        data = await websocket.receive_text()
        radio_url = data.strip()
        
        print(f"Requested Station: {radio_url}")

        # 2. Start the transcription engine
        await transcribe_radio_stream(radio_url, websocket)

    except WebSocketDisconnect:
        print("📱 Client disconnected")
    except Exception as e:
        print(f"❌ WebSocket Error: {e}")