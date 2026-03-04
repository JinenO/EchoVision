from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    
    username = Column(String, unique=True, index=True, nullable=True)
    birthday = Column(DateTime, nullable=True)
    gender = Column(String, nullable=True)
    profile_picture = Column(String, default="default_avatar.png")
    
    is_verified = Column(Boolean, default=False)
    verification_code = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # --- RELATIONSHIPS ---
    # One user can have MANY uploads and MANY transcriptions
    uploads = relationship("FileUpload", back_populates="owner")
    transcriptions = relationship("Transcription", back_populates="owner")

class FileUpload(Base):
    __tablename__ = "file_uploads"
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String)
    file_path = Column(String)
    language = Column(String)
    
    # --- NEW: The Status Tracker ---
    status = Column(String, default="processing") # Can be: "processing", "completed", "failed"
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Linked to User
    user_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="uploads")
    
    # Linked to Transcription
    transcription = relationship("Transcription", back_populates="file", uselist=False)
    
class Transcription(Base):
    __tablename__ = "transcriptions"
    id = Column(Integer, primary_key=True, index=True)
    
    # Notice: No more "station_name" or "source_type"! It's strictly for files now.
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 1. Linked to User
    user_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="transcriptions")
    
    # 2. Linked to FileUpload
    file_id = Column(Integer, ForeignKey("file_uploads.id"))
    file = relationship("FileUpload", back_populates="transcription")

# --- TV Content Table (No User Relationship needed) ---
class TVContent(Base):
    __tablename__ = "tv_content"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(Text, nullable=True)
    video_url = Column(String, nullable=False)
    thumbnail_url = Column(String, nullable=True)
    subtitle_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())