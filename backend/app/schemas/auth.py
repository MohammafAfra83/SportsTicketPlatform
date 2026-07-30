from pydantic import BaseModel, EmailStr


# --- Input Models (Request) ---
class OTPRequest(BaseModel):
    phone_number: str


class UserSignup(BaseModel):
    phone_number: str
    email: EmailStr
    password: str
    otp_code: str
    first_name: str
    last_name: str
    city: str


class UserLogin(BaseModel):
    phone_number: str
    password: str


# --- Output Models (Response) ---
class OTPResponse(BaseModel):
    message: str
    otp: str
    expires_in: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    message: str | None = None
