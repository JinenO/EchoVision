from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import jwt
import random

# --- CONFIGURATION ---
# SECRET_KEY: Change this to a random long string for production!
SECRET_KEY = "super_secret_echo_vision_key_change_me_later"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 3000 # Token lasts for 50 hours (for testing)

# Password Hashing Tool
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# --- NEW: TOKEN GENERATOR ---
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# --- GENERATE 6-DIGIT CODE ---
def generate_verification_code():
    # This generates a string like "059281" (always 6 digits)
    return f"{random.randint(0, 999999):06d}"
