import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

# 1. Load the password from the .env file
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("❌ DATABASE_URL is missing in .env file!")

# 2. Create the Connection Engine
engine = create_async_engine(DATABASE_URL, echo=True)

# 3. Create a Session Factory (Modern SQLAlchemy 2.0 way)
# We name it SessionLocal to match the import in your routers
SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# 4. Base Class for our Tables
Base = declarative_base()

# 5. Dependency for FastAPI
async def get_db():
    async with SessionLocal() as session:
        yield session