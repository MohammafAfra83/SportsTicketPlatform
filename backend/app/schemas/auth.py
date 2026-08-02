from pydantic import BaseModel, EmailStr, Field


# --- Input Models (Request) ---
class OTPRequest(BaseModel):
    phone_number: str = Field(
        ...,
        pattern=r"^09[0-9]{9}$",
        description="Must be a valid 11-digit Iranian phone number "
        "starting with 09",
    )


class UserSignup(BaseModel):
    phone_number: str = Field(..., pattern=r"^09[0-9]{9}$")
    email: EmailStr
    password: str = Field(..., min_length=8)
    otp_code: str = Field(..., min_length=5, max_length=5)
    first_name: str = Field(..., min_length=2)
    last_name: str = Field(..., min_length=2)
    city: str = Field(..., min_length=2)


class UserLogin(BaseModel):
    phone_number: str = Field(..., pattern=r"^09[0-9]{9}$")
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
