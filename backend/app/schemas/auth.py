from pydantic import BaseModel


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
