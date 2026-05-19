from sqlalchemy import create_engine
from sqlalchemy import Engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import DeclarativeBase

from typing import Generator

DATABASE_URL: str = "sqlite:///./database.db"

engine: Engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

class Base(DeclarativeBase):
    ...

def get_db() -> Generator:
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()

