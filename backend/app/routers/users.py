from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy import select
from jose import JWTError, jwt

import shutil #Used to save the file
import uuid #Used to generate unique file names

# Import from your main app folder
from app import models, schemas, utils, email_service
from app.database import get_db

# Create the router
router = APIRouter(prefix="/users", tags=["Authentication & Users"])

# This tells FastAPI to look for the token here
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")

# --- SECURITY GUARD: GET CURRENT USER ---
# This function intercepts requests, checks the Token, and finds who is logged in
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # Decode the token to get the email
        payload = jwt.decode(token, utils.SECRET_KEY, algorithms=[utils.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # Find the user in the database
    query = select(models.User).where(models.User.email == email)
    result = await db.execute(query)
    user = result.scalar_one_or_none()

    if user is None:
        raise credentials_exception
    return user

# --- 1. REGISTER ENDPOINT (Existing) ---
@router.post("/register", response_model=schemas.UserResponse)
async def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    query = select(models.User).where(models.User.email == user.email)
    result = await db.execute(query)
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pwd = utils.hash_password(user.password)
    final_username = user.username if user.username else user.email.split("@")[0]

    # NEW: Generate the 6-digit code
    v_code = utils.generate_verification_code()

    new_user = models.User(
        email=user.email,
        hashed_password=hashed_pwd,
        username=final_username,
        birthday=user.birthday,
        gender=user.gender,
        profile_picture="default_avatar.png",
        is_verified=False,         # <--- Set to False!
        verification_code=v_code   # <--- Save the code!
    )

    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    # NEW: Send the email!
    email_service.send_verification_email(new_user.email, v_code)

    return new_user

# --- 2. VERIFY ENDPOINT ---
@router.post("/verify")
async def verify_user(verify_data: schemas.UserVerify, db: Session = Depends(get_db)):
    # Find the user
    query = select(models.User).where(models.User.email == verify_data.email)
    result = await db.execute(query)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.is_verified:
        raise HTTPException(status_code=400, detail="User is already verified")

    # Check if the code matches
    if user.verification_code != verify_data.code:
        raise HTTPException(status_code=400, detail="Invalid verification code")

    # Success! Mark as verified and clear the code
    user.is_verified = True
    user.verification_code = None
    await db.commit()

    return {"message": "Email verified successfully! You can now log in."}

# --- 3. LOGIN ENDPOINT ---
@router.post("/login")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    query = select(models.User).where(models.User.email == form_data.username)
    result = await db.execute(query)
    user = result.scalar_one_or_none()

    if not user or not utils.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # NEW: Block login if not verified!
    if not user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email address first."
        )

    access_token = utils.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

# --- 4. GET USER PROFILE (NEW) ---
# Flutter calls this to load the "Profile Settings" screen
@router.get("/me", response_model=schemas.UserResponse)
async def read_users_me(current_user: models.User = Depends(get_current_user)):
    # Because of the Security Guard, 'current_user' is already loaded!
    return current_user

# --- 5. UPDATE USER PROFILE (Includes Email and Username) ---
@router.put("/me", response_model=schemas.UserResponse)
async def update_user_profile(
    update_data: schemas.UserUpdate, 
    current_user: models.User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    # Check if they are trying to change their email
    if update_data.email is not None and update_data.email != current_user.email:
        # Make sure the new email isn't already used by another account!
        query = select(models.User).where(models.User.email == update_data.email)
        result = await db.execute(query)
        if result.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="This email is already taken")
        current_user.email = update_data.email

    # Update the rest of the fields
    if update_data.username is not None:
        current_user.username = update_data.username
    if update_data.birthday is not None:
        current_user.birthday = update_data.birthday
    if update_data.gender is not None:
        current_user.gender = update_data.gender
    if update_data.profile_picture is not None:
        current_user.profile_picture = update_data.profile_picture

    await db.commit()
    await db.refresh(current_user)
    return current_user

# --- LOGGED IN: Change Password (Requires Current Password) ---
# --- LOGGED IN STEP 1: Just verify the current password ---
@router.post("/me/verify-password")
async def verify_current_password(
    req: schemas.VerifyPasswordRequest, 
    current_user: models.User = Depends(get_current_user)
):
    if not utils.verify_password(req.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    
    return {"message": "Password is correct."}

@router.put("/me/password")
async def change_password(
    pass_data: schemas.ChangePasswordRequest, 
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify the old password
    if not utils.verify_password(pass_data.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    
    # Save the new password
    current_user.hashed_password = utils.hash_password(pass_data.new_password)
    await db.commit()
    return {"message": "Password updated successfully"}

# --- LOGGED OUT STEP 2: Verify the Code First ---
@router.post("/verify-reset-code")
async def verify_reset_code(req: schemas.VerifyResetCodeRequest, db: Session = Depends(get_db)):
    query = select(models.User).where(models.User.email == req.email)
    result = await db.execute(query)
    user = result.scalar_one_or_none()
    
    if not user or user.verification_code != req.code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
        
    return {"message": "Code verified successfully."}

# --- LOGGED OUT STEP 3: Save New Password ---
@router.post("/reset-password")
async def reset_password(request: schemas.ResetPasswordRequest, db: Session = Depends(get_db)):
    query = select(models.User).where(models.User.email == request.email)
    result = await db.execute(query)
    user = result.scalar_one_or_none()
    
    # Double check the code just in case
    if not user or user.verification_code != request.code:
        raise HTTPException(status_code=400, detail="Invalid session or code")
        
    user.hashed_password = utils.hash_password(request.new_password)
    user.verification_code = None # Clear the code so it can't be reused
    await db.commit()
    return {"message": "Password reset successfully."}

# --- 7. UPLOAD PROFILE PICTURE (NON-DESTRUCTIVE CROP) ---
@router.post("/me/upload-profile-picture")
async def upload_profile_picture(
    file: UploadFile = File(...),
    original_file: UploadFile = File(None), # NEW: Accepts the uncropped version!
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    file_extension = file.filename.split(".")[-1].lower()
    allowed_extensions = ["jpg", "jpeg", "png", "gif", "webp"]
    
    if file_extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="File extension not allowed.")

    # Create one shared unique ID for both files
    unique_id = uuid.uuid4().hex[:8]
    cropped_filename = f"user_{current_user.id}_{unique_id}.{file_extension}"
    
    # 1. Save the small cropped picture
    with open(f"uploads/profile_pics/{cropped_filename}", "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # 2. Save the MASSIVE ORIGINAL picture with a predictable name!
    if original_file:
        original_filename = f"user_{current_user.id}_{unique_id}_original.{file_extension}"
        with open(f"uploads/profile_pics/{original_filename}", "wb") as buffer:
            shutil.copyfileobj(original_file.file, buffer)

    file_url = f"http://127.0.0.1:8000/uploads/profile_pics/{cropped_filename}"

    current_user.profile_picture = file_url
    await db.commit()
    await db.refresh(current_user)

    return {"message": "Profile picture updated successfully", "profile_picture": file_url}
    
# --- FORGOT PASSWORD: Send the Code ---
@router.post("/forgot-password")
async def forgot_password(request: schemas.ForgotPasswordRequest, db: Session = Depends(get_db)):
    query = select(models.User).where(models.User.email == request.email)
    result = await db.execute(query)
    user = result.scalar_one_or_none()
    
    # If the user exists, generate a code and email it
    if user:
        reset_code = utils.generate_verification_code()
        user.verification_code = reset_code
        await db.commit()
        email_service.send_verification_email(user.email, reset_code)
        
    # Always return a success message to prevent attackers from guessing emails
    return {"message": "If the email is registered, a code has been sent."}

# --- RESET PASSWORD: Verify Code & Save New Password ---
@router.post("/reset-password")
async def reset_password(request: schemas.ResetPasswordRequest, db: Session = Depends(get_db)):
    query = select(models.User).where(models.User.email == request.email)
    result = await db.execute(query)
    user = result.scalar_one_or_none()
    
    # Check if user exists AND if the code matches
    if not user or user.verification_code != request.code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
        
    # Success! Hash the new password, save it, and clear the code
    user.hashed_password = utils.hash_password(request.new_password)
    user.verification_code = None
    await db.commit()
    
    return {"message": "Password reset successfully."}