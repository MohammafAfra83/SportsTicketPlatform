from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from app.schemas.auth import OTPRequest, OTPResponse, UserSignup, TokenResponse
from app.redis_client import generate_and_set_otp, verify_otp
from app.database import get_db_cursor
from app.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# Swagger Security System for the Authorize Button 🔓
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


@router.post(
    "/otp",
    response_model=OTPResponse,
    status_code=status.HTTP_200_OK,
    responses={500: {"description": "Internal Server Error"}},
)
def request_otp(data: OTPRequest):
    # Delegate generation and Redis storage to our helper function
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
    responses={
        400: {
            "description": (
                "Invalid/Expired OTP or User/Email already exists"
            )
        },
        500: {"description": "Database error"},
    },
)
def signup(data: UserSignup):
    # 1. Verify OTP using our helper (it also handles deletion on success)
    if not verify_otp(data.phone_number, data.otp_code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP code.",
        )

    hashed_pw = get_password_hash(data.password)
    try:
        with get_db_cursor() as cursor:
            # 2. Validating that the phone number or email
            #    does not already exist
            check_query = """
                SELECT user_id FROM users
                WHERE phone_number = %s OR email = %s;
            """
            cursor.execute(check_query, (data.phone_number, data.email))
            if cursor.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "User with this phone number or "
                        "email already exists"
                    ),
                )

            # 3. Direct User Insertion into the Database Without an ORM
            insert_query = """
                INSERT INTO users (
                    first_name,
                    last_name,
                    phone_number,
                    email,
                    password_hash,
                    city,
                    role
                )
                VALUES (%s, %s, %s, %s, %s, %s, 'audience')
                RETURNING user_id, role;
            """
            cursor.execute(
                insert_query,
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

            # 4. Issuing a JWT using user_id
            token_data = {
                "sub": str(new_user["user_id"]),
                "role": new_user["role"],
            }
            access_token = create_access_token(data=token_data)

            return {
                "access_token": access_token,
                "token_type": "bearer",
                "message": "Signup successful",
            }

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    responses={
        401: {"description": "Invalid phone number or password"},
        500: {"description": "Database error"},
    },
)
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    Logging in using the standard OAuth2 form.
    Use your phone number as the username on Swagger.
    """
    with get_db_cursor() as cursor:
        select_query = """
            SELECT user_id, password_hash, role
            FROM users
            WHERE phone_number = %s;
        """
        cursor.execute(select_query, (form_data.username,))
        user = cursor.fetchone()

        if not user or not verify_password(
            form_data.password,
            user["password_hash"],
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
        access_token = create_access_token(data=token_data)

        return {
            "access_token": access_token,
            "token_type": "bearer",
            "message": "Login successful",
        }


@router.get(
    "/me/test-auth",
    tags=["Authentication"],
    responses={401: {"description": "Not authenticated"}},
)
def test_authentication(token: str = Depends(oauth2_scheme)):
    """This endpoint is for testing the JWT security lock."""
    return {
        "message": "You have been successfully authenticated!",
        "token_received": token,
    }
