import os
import shutil
import asyncio
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import select

from app import models, schemas
from app.database import get_db, SessionLocal # SessionLocal is needed for background tasks
from app.routers.users import get_current_user

router = APIRouter(prefix="/files", tags=["File Uploads & History"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# --- THE BACKGROUND AI WORKER ---
async def process_transcription_task(file_id: int):
    await asyncio.sleep(10) # Simulate AI processing time
    async with SessionLocal() as db:
        query = select(models.FileUpload).where(models.FileUpload.id == file_id)
        result = await db.execute(query)
        file = result.scalar_one_or_none()

        if file:
            # Create the "Finished" transcription
            new_trans = models.Transcription(
                content=f"AI Transcription completed for: {file.filename}",
                user_id=file.user_id,
                file_id=file.id
            )
            file.status = "completed"
            db.add(new_trans)
            await db.commit()
            print(f"✅ AI Processing Finished for File {file_id}")

# --- UPLOAD ENDPOINT ---
@router.post("/upload", response_model=schemas.FileUploadResponse)
async def upload_audio_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    language: str = Form("en"),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    new_file = models.FileUpload(
        filename=file.filename,
        file_path=file_path,
        language=language,
        user_id=current_user.id,
        status="processing"
    )
    db.add(new_file)
    await db.commit()
    
    # Start the "AI" in the background
    background_tasks.add_task(process_transcription_task, new_file.id)

    # Re-fetch with selectinload to avoid the 500 Error
    query = select(models.FileUpload).where(
        models.FileUpload.id == new_file.id
    ).options(selectinload(models.FileUpload.transcription))
    
    result = await db.execute(query)
    return result.scalar_one()

# --- HISTORY ENDPOINT ---
@router.get("/", response_model=list[schemas.FileUploadResponse])
async def get_my_files(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    query = select(models.FileUpload).where(
        models.FileUpload.user_id == current_user.id
    ).options(selectinload(models.FileUpload.transcription))
    
    result = await db.execute(query)
    return result.scalars().all()