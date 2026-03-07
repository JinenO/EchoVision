from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.radio_transcriber import transcribe_radio_stream

# Create the router for radio endpoints
router = APIRouter(tags=["Radio WebSocket"])

# Connects to: ws://127.0.0.1:8000/ws/radio
@router.websocket("/ws/radio")
async def websocket_endpoint(websocket: WebSocket, url: str = None, lang: str = "en"):
    await websocket.accept()
    print("📱 Client connected to WebSocket")
    
    try:
        if not url:
            data = await websocket.receive_text()
            radio_url = data.strip()
        else:
            radio_url = url
            
        print(f"Requested Station: {radio_url} (Language: {lang})")
        await transcribe_radio_stream(radio_url, websocket)

    except WebSocketDisconnect:
        print("🔌 Client disconnected")
    except Exception as e:
        print(f"❌ WebSocket Error: {e}")