from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import (
    OAuth2PasswordRequestForm,
    OAuth2PasswordBearer,
)
from app.schemas.auth import (
    OTPRequest,
    OTPResponse,
    UserSignup,
    TokenResponse,
)
from app.redis_client import (
    generate_and_set_otp,
    verify_otp,
)
from app.database import get_db_cursor
from app.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)

router = APIRouter(
    prefix="/api/auth", tags=["Authentication"]
)
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/auth/login"
)


@router.post(
    "/otp",
    response_model=OTPResponse,
    status_code=status.HTTP_200_OK,
)
def request_otp(data: OTPRequest):
    otp_code = generate_and_set_otp(data.phone_number)
    return {
        "message": "OTP sent successfully",
        "otp": otp_code,
        "expires_in": "120 seconds",
    }


@router.post(
    "/signup",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
)
def signup(data: UserSignup):
    if not verify_otp(data.phone_number, data.otp_code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP code.",
        )
    hashed_pw = get_password_hash(data.password)
    try:
        with get_db_cursor() as cursor:
            cursor.execute(
                "SELECT user_id FROM users WHERE phone_number = %s "
                "OR email = %s;",
                (data.phone_number, data.email),
            )
            if cursor.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail="User with this phone number or email "
                    "already exists",
                )

            cursor.execute(
                "INSERT INTO users (first_name, last_name, "
                "phone_number, email, password_hash, city, role) "
                "VALUES (%s, %s, %s, %s, %s, %s, 'audience') "
                "RETURNING user_id, role;",
                (
                    data.first_name,
                    data.last_name,
                    data.phone_number,
                    data.email,
                    hashed_pw,
                    data.city,
                ),
            )
            new_user = cursor.fetchone()
            token_data = {
                "sub": str(new_user["user_id"]),
                "role": new_user["role"],
            }

            return {
                "access_token": create_access_token(data=token_data),
                "token_type": "bearer",
                "message": "Signup successful",
            }
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500, detail=f"Database error: {str(e)}"
        )


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
)
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT user_id, password_hash, role FROM users "
            "WHERE phone_number = %s;",
            (form_data.username,),
        )
        user = cursor.fetchone()
        if not user or not verify_password(
            form_data.password, user["password_hash"]
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid phone number or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        token_data = {
            "sub": str(user["user_id"]),
            "role": user["role"],
        }
        return {
            "access_token": create_access_token(data=token_data),
            "token_type": "bearer",
            "message": "Login successful",
        }


@router.get(
    "/me/test-auth",
    response_model=dict,
    tags=["Authentication"],
)
def test_authentication(
    token: str = Depends(oauth2_scheme),
):
    """This endpoint is for testing the JWT security lock."""
    return {
        "message": "You have been successfully authenticated!",
        "token_received": token,
    }
