from pydantic import BaseModel


# --- Input Models (Request) ---
class OTPRequest(BaseModel):
    phone: str


class UserSignup(BaseModel):
    phone: str
    password: str
    otp_code: str
    first_name: str
    last_name: str


class UserLogin(BaseModel):
    phone: str
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
