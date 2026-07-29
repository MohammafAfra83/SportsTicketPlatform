from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from app.schemas.auth import OTPRequest, OTPResponse, UserSignup, TokenResponse
from app.redis_client import redis_client
from app.database import get_db_cursor
from app.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
import random

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# Configuring the security system in Swagger to add the Authorize button 🔓
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


@router.post(
    "/otp",
    response_model=OTPResponse,
    status_code=status.HTTP_200_OK,
    responses={500: {"description": "Internal Server Error"}},
)
def request_otp(data: OTPRequest):
    # Generate a random 6-digit OTP code.
    otp_code = str(random.randint(100000, 999999))
    # Store the OTP in Redis with a TTL of 120 seconds.
    redis_key = f"otp:{data.phone}"
    redis_client.set(redis_key, otp_code, ex=120)

    return {
        "message": "OTP sent successfully",
        "otp": otp_code,
        "expires_in": "120 seconds",
    }


@router.post(
    "/signup",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        400: {"description": "Invalid or expired OTP / User already exists"},
        500: {"description": "Database error"},
    },
)
def signup(data: UserSignup):
    # Retrieve and validate the OTP from Redis.
    redis_key = f"otp:{data.phone}"
    saved_otp = redis_client.get(redis_key)

    if not saved_otp or saved_otp != data.otp_code:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    hashed_pw = get_password_hash(data.password)

    try:
        with get_db_cursor() as cursor:
            # Check whether the phone number is already registered.
            cursor.execute(
                "SELECT id FROM users WHERE phone = %s;",
                (data.phone,),
            )
            if cursor.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail="User already exists",
                )

            insert_query = (
                "INSERT INTO users (phone, password_hash, "
                "first_name, last_name, role) "
                "VALUES (%s, %s, %s, %s, 'audience') "
                "RETURNING id, role;"
            )
            cursor.execute(
                insert_query,
                (
                    data.phone,
                    hashed_pw,
                    data.first_name,
                    data.last_name,
                ),
            )
            new_user = cursor.fetchone()

            token_data = {"sub": str(new_user["id"]), "role": new_user["role"]}
            access_token = create_access_token(data=token_data)

            # Delete the consumed OTP from Redis to prevent reuse.
            redis_client.delete(redis_key)

            return {
                "access_token": access_token,
                "token_type": "bearer",
                "message": "Signup successful",
            }
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    responses={
        401: {"description": "Invalid phone or password"},
        500: {"description": "Database error"},
    },
)
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """
       The OAuth2 Form standard is used for login.
    Note: You must enter your mobile number in the 'username' field in Swagger.
    """
    with get_db_cursor() as cursor:
        select_query = "SELECT id, password_hash, role FROM users WHERE phone = %s;"
        cursor.execute(select_query, (form_data.username,))
        user = cursor.fetchone()

        if not user or not verify_password(
            form_data.password,
            user["password_hash"],
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid phone or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        token_data = {
            "sub": str(user["id"]),
            "role": user["role"],
        }
        access_token = create_access_token(data=token_data)

        return {
            "access_token": access_token,
            "token_type": "bearer",
            "message": "Login successful",
        }


# --- Test route to demonstrate security locking on endpoints ---
@router.get(
    "/me/test-auth",
    tags=["Authentication"],
    responses={401: {"description": "Not authenticated"}},
)
def test_authentication(token: str = Depends(oauth2_scheme)):
    """This endpoint only works with a valid token."""
    return {
        "message": "You have been successfully authenticated!",
        "token_received": token,
    }
