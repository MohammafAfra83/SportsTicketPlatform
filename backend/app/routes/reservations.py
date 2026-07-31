from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from app.schemas.reservations import ReservationRequest, ReservationResponse
from app.database import get_db_cursor
from app.config import settings
from app.redis_client import clear_ticket_cache

router = APIRouter(prefix="/api/reservations", tags=["Reservations"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


# Dependency to extract and verify the current user from JWT
def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    try:
        # If SECRET_KEY resides in security.py, adjust the import.
        # Assuming settings.SECRET_KEY is used based on main.py.
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=["HS256"],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            )
        return int(user_id)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token",
        )


@router.post(
    "/",
    response_model=ReservationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Reserve a ticket with Pessimistic Locking",
)
def reserve_ticket(
    data: ReservationRequest, user_id: int = Depends(get_current_user_id)
):
    try:
        with get_db_cursor() as cursor:
            # 1. Lock ticket row to prevent race conditions
            cursor.execute(
                """
                SELECT remaining_capacity, is_active
                FROM tickets
                WHERE ticket_id = %s
                FOR UPDATE;
                """,
                (data.ticket_id,),
            )
            ticket = cursor.fetchone()

            # 2. Validation Checks
            if not ticket:
                raise HTTPException(status_code=404, detail="Ticket not found")
            if not ticket["is_active"]:
                raise HTTPException(
                    status_code=400, detail="Match is currently inactive"
                )
            if ticket["remaining_capacity"] <= 0:
                raise HTTPException(
                    status_code=400, detail="Ticket is completely sold out"
                )

            # 3. Decrease remaining capacity
            cursor.execute(
                """
                UPDATE tickets
                SET remaining_capacity = remaining_capacity - 1
                WHERE ticket_id = %s;
                """,
                (data.ticket_id,),
            )

            # 4. Create reservation record with a 15-minute expiration
            insert_query = (
                "INSERT INTO reservations "
                "(user_id, ticket_id, status, expires_at) "
                "VALUES (%s, %s, 'pending', "
                "NOW() + INTERVAL '15 minutes') "
                "RETURNING reservation_id, expires_at;"
            )
            cursor.execute(insert_query, (user_id, data.ticket_id))
            reservation = cursor.fetchone()

            # Explicitly commit the transaction
            # (if your context manager doesn't auto-commit)
            cursor.connection.commit()
            # Invalidate Redis cache because remaining_capacity has changed! ⚡
            clear_ticket_cache()

            return {
                "reservation_id": reservation["reservation_id"],
                "ticket_id": data.ticket_id,
                "status": "pending",
                "message": "Ticket successfully reserved for 15 minutes.",
                "expires_at": reservation["expires_at"],
            }

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )
