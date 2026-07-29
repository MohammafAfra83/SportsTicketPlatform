from fastapi import APIRouter, HTTPException, status
from app.schemas.auth import OTPRequest, UserSignup, UserLogin
from app.redis_client import redis_client
from app.database import get_db_cursor
from app.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
import random

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/otp")
def request_otp(data: OTPRequest):
    # Generate a random 6-digit OTP code.
    otp_code = str(random.randint(100000, 999999))

    # Store the OTP in Redis with a TTL of 120 seconds.
    redis_key = f"otp:{data.phone}"
    redis_client.set(redis_key, otp_code, ex=120)

    # In a production environment, the OTP should be sent via SMS.
    # For testing purposes, the OTP is returned in the response.
    return {
        "message": "OTP sent successfully",
        "otp": otp_code,
        "expires_in": "120 seconds",
    }


@router.post("/signup")
def signup(data: UserSignup):
    # Retrieve and validate the OTP from Redis.
    redis_key = f"otp:{data.phone}"
    saved_otp = redis_client.get(redis_key)

    if not saved_otp or saved_otp != data.otp_code:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    hashed_pw = get_password_hash(data.password)

    # Insert the user directly into PostgreSQL without using an ORM.
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

            # Insert the new user.
            # If your database column names differ, update this query
            # accordingly.
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

            # Generate a JWT access token for the newly registered user.
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
        error_message = f"Database error: {str(e)}"
        raise HTTPException(status_code=500, detail=error_message)


@router.post("/login")
def login(data: UserLogin):
    with get_db_cursor() as cursor:
        select_query = (
            "SELECT id, password_hash, role "
            "FROM users WHERE phone = %s;"
        )
        cursor.execute(select_query, (data.phone,))
        user = cursor.fetchone()

        if not user or not verify_password(data.password, user["password_hash"]):
            raise HTTPException(
                status_code=401,
                detail="Invalid phone or password",
            )

        token_data = {
            "sub": str(user["id"]),
            "role": user["role"],
        }
        access_token = create_access_token(data=token_data)
        return {
            "access_token": access_token,
            "token_type": "bearer",
        }
