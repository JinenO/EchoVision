from fastapi import FastAPI
from contextlib import asynccontextmanager
from fastapi.staticfiles import StaticFiles
import os
from app.database import engine, Base
from app.routers import users, radio, tv, files

@asynccontextmanager
async def lifespan(app: FastAPI):
    # This automatically creates your tables when the server starts
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(lifespan=lifespan)

# --- UPDATED: Create main folders AND subfolders ---
os.makedirs("uploads", exist_ok=True)
os.makedirs("uploads/profile_pics", exist_ok=True) # <-- NEW: Dedicated folder for avatars
os.makedirs("static", exist_ok=True)

# Mount directories so files are accessible via URL
# Note: Because we mount the root "uploads", the avatars will be accessible 
# at http://127.0.0.1:8000/uploads/profile_pics/filename.png
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.mount("/static", StaticFiles(directory="static"), name="static")

# Register Routers
app.include_router(users.router)
app.include_router(radio.router)
app.include_router(tv.router)
app.include_router(files.router)

@app.get("/")
def read_root():
    return {"status": "online", "message": "EchoVision AI Server is Ready"}