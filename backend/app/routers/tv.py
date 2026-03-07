from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import List

from app import models, schemas
from app.database import get_db

# Create the router 
# We use prefix="/tv" so the URL becomes http://127.0.0.1:8000/tv
router = APIRouter(prefix="/tv", tags=["TV Content"])

# --- GET ALL TV VIDEOS ---
# Notice we use response_model=List[...] because we are returning multiple videos!
@router.get("/", response_model=List[schemas.TVContentResponse])
async def get_all_tv_content(db: Session = Depends(get_db)):
    # Query the database for everything in the TVContent table
    query = select(models.TVContent)
    result = await db.execute(query)
    videos = result.scalars().all()
    
    return videos