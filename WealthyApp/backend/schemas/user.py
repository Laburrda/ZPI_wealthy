from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class UserUpdate(BaseModel):
    # email: EmailStr | None = None # TODO: consider option of changing email with full validation and authentication
    full_name: str | None = None
    password: str | None = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"