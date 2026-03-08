from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# 1. What the User sends during Registration
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    
    # These are Optional! If UI doesn't send them, they default to None
    username: Optional[str] = None
    birthday: Optional[datetime] = None
    gender: Optional[str] = None

# 2. What we send back to the App (Response)
class UserResponse(BaseModel):
    id: int
    email: EmailStr
    username: Optional[str]
    birthday: Optional[datetime] = None
    gender: Optional[str] = None
    profile_picture: str
    created_at: datetime

    class Config:
        from_attributes = True

# 3. What the App sends to update a profile (Now includes email)
class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None  # <-- Added this!
    birthday: Optional[datetime] = None
    gender: Optional[str] = None
    profile_picture: Optional[str] = None

# 4. What the App sends ONLY when changing a password
class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str

# 5. What the App sends to verify the email
class UserVerify(BaseModel):
    email: EmailStr
    code: str

from typing import Optional, List # Make sure List is imported at the top if it isn't already!

# ... (Keep all your User schemas above this) ...

# --- TV Content Response ---
class TVContentResponse(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    video_url: str
    thumbnail_url: Optional[str] = None
    subtitle_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# --- NEW: Transcription & File Upload Responses ---

# 1. The Transcription data
class TranscriptionResponse(BaseModel):
    id: int
    content: str
    created_at: datetime

    class Config:
        from_attributes = True

# 2. The File Upload data (Notice how it includes the transcription inside it!)
class FileUploadResponse(BaseModel):
    id: int
    filename: str
    file_path: str
    language: str
    
    # --- NEW: Tell Flutter the status! ---
    status: str 
    
    created_at: datetime
    transcription: Optional[TranscriptionResponse] = None

    class Config:
        from_attributes = True

class PasswordUpdateWithCode(BaseModel):
    current_password: str
    new_password: str
    code: str  # The 6-digit code from email

# --- NEW: Password Reset Verification ---
class VerifyCodeRequest(BaseModel):
    code: str  # This handles the 6-digit code from the email

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class VerifyResetCodeRequest(BaseModel):
    email: EmailStr
    code: str

class VerifyPasswordRequest(BaseModel):
    current_password: str