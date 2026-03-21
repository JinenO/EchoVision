import subprocess
import os
import json
import sys
import asyncio
import webrtcvad
from vosk import Model, KaldiRecognizer
from fastapi import WebSocket, WebSocketDisconnect

# --- CONFIGURATION ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "model")
FFMPEG_PATH = os.path.join(BASE_DIR, "ffmpeg.exe") 

if sys.platform == "win32" and not os.path.exists(FFMPEG_PATH):
    FFMPEG_PATH = "ffmpeg"

print(f"🚀 Loading AI Model from: {MODEL_PATH}")
if not os.path.exists(MODEL_PATH):
    print("❌ CRITICAL ERROR: Model folder not found!")
    model = None
else:
    model = Model(MODEL_PATH)

# VAD Mode 2: Balanced
vad = webrtcvad.Vad(2)

# --- TUNING ---
MAX_SCORE = 50           
MUSIC_THRESHOLD = 40     
STARTUP_SCORE = -200     

# Hallucination Filter
GHOST_WORDS = {
    "the", "a", "an", "and", "of", "to", "in", "it", "is", "that", 
    "so", "but", "or", "for", "on", "at", "by", "my", "me", "be", "do", 
    "uh", "um", "huh", "oh", "ah", "hmm", "hey", "yeah", "yep", "[unk]"
}

async def safe_send(websocket: WebSocket, message: str):
    try:
        await websocket.send_text(message)
        return True
    except (RuntimeError, WebSocketDisconnect):
        return False

async def transcribe_radio_stream(url: str, websocket: WebSocket):
    if not model:
        await safe_send(websocket, "❌ Error: Server has no AI Model loaded.")
        return

    if not await safe_send(websocket, "📡 Connecting to Radio Tower...") : return

    process = subprocess.Popen(
        [
            FFMPEG_PATH, "-i", url, "-ar", "16000", "-ac", "1", "-f", "s16le",
            "-fflags", "nobuffer", "-flags", "low_delay", "-analyzeduration", "0", "-"
        ],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
    )

    rec = KaldiRecognizer(model, 16000)
    FRAME_SIZE = 960 
    loop = asyncio.get_event_loop()
    
    music_score = STARTUP_SCORE 
    is_music_mode = False
    buffer = b"" 
    frames_processed = 0
    
    last_partial = "" 

    try:
        if not await safe_send(websocket, "👂 Listening..."): return 
        
        while True:
            chunk = await loop.run_in_executor(None, process.stdout.read, 4000)
            if not chunk: break
            buffer += chunk
            
            while len(buffer) >= FRAME_SIZE:
                frame = buffer[:FRAME_SIZE]
                buffer = buffer[FRAME_SIZE:] 
                frames_processed += 1

                # --- NEW: Calculate exact audio timestamp! ---
                # 960 bytes / 32000 bytes per second = 0.03 seconds per frame
                current_audio_time = frames_processed * 0.03 

                if frames_processed % 50 == 0:
                    try:
                        if websocket.client_state.name == "DISCONNECTED": raise WebSocketDisconnect()
                    except: pass

                try:
                    is_speech = vad.is_speech(frame, 16000)
                except:
                    is_speech = False

                found_human_activity = False

                if is_speech:
                    # 1. CHECK FOR FULL SENTENCE (Final Result)
                    if rec.AcceptWaveform(frame):
                        result = json.loads(rec.Result())
                        text = result.get("text", "").strip()
                        
                        if text and not (len(text.split()) == 1 and text.lower() in GHOST_WORDS):
                            print(f"📝 Final: {text}")
                            found_human_activity = True
                            last_partial = "" 
                            
                            # --- NEW: Attach Timestamp and Status! ---
                            result["audio_time"] = current_audio_time
                            result["is_final"] = True
                            if not await safe_send(websocket, json.dumps(result)):
                                raise WebSocketDisconnect()
                    
                    # 2. CHECK FOR PARTIAL WORDS (Live Typing Result)
                    else:
                        partial_result = json.loads(rec.PartialResult())
                        partial_text = partial_result.get("partial", "").strip()
                        
                        if partial_text and len(partial_text) > 2: 
                             found_human_activity = True
                             
                             if partial_text != last_partial:
                                 last_partial = partial_text
                                 
                                 # --- NEW: Attach Timestamp and Status! ---
                                 partial_result["audio_time"] = current_audio_time
                                 partial_result["is_final"] = False
                                 if not await safe_send(websocket, json.dumps(partial_result)):
                                     raise WebSocketDisconnect()

                # --- SCORING LOGIC ---
                if found_human_activity:
                    music_score = -50 
                    is_music_mode = False
                else:
                    music_score += 1
                
                if music_score > MAX_SCORE: music_score = MAX_SCORE

                # --- TRIGGER MUSIC MODE ---
                if music_score >= MUSIC_THRESHOLD and not is_music_mode:
                    print("🎵 Music Mode ON")
                    if not await safe_send(websocket, "[[MUSIC_MODE]]"):
                        raise WebSocketDisconnect()
                    is_music_mode = True
                    rec.Reset()

    except (WebSocketDisconnect, RuntimeError):
        print("🔌 Client disconnected.")
    except Exception as e:
        print(f"⚠️ Error: {e}")
    finally:
        process.terminate()