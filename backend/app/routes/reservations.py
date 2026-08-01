from fastapi import APIRouter, HTTPException, status, Depends, BackgroundTasks
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from app.schemas.reservations import ReservationRequest, ReservationResponse
from app.database import get_db_cursor
from app.config import settings
from app.redis_client import clear_ticket_cache
import asyncio
import logging

# Setting up a logger to display alerts in the monitoring system or terminal.
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/reservations",
    tags=["Reservations"],
)
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/auth/login",
)


# Dependency to extract and verify the current user from JWT
def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    try:
        # Assuming settings.JWT_SECRET_KEY is used based on main.py.
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


# ---------------------------------------------------------
# Bonus-Feature: Background Task for Expiration Reminder
# ---------------------------------------------------------
async def expiration_reminder_task(reservation_id: int, user_id: int):
    """
    This task runs in the background and waits for 13 minutes.
    It does not block the user.
    After 13 minutes, it checks the database.
    If the reservation is still pending, it generates a warning
    message.
    """
    # Non-blocking pause for 13 minutes
    # 💡To quickly test the system on your own machine,
    # you can set this value to 10 seconds:
    # await asyncio.sleep(10)
    await asyncio.sleep(13 * 60)

    try:
        with get_db_cursor() as cursor:
            # check if the reservation is still pending
            cursor.execute(
                "SELECT status FROM reservations WHERE reservation_id = %s;",
                (reservation_id,),
            )
            result = cursor.fetchone()

            # If the payment had not yet been processed (pending):
            if result and result["status"] == "pending":
                # In a real-world system, the SMS sending API is
                # called here.
                # E.g. Kavenegar or Faraz SMS for notifications.
                reminder_msg = (
                    "🔔 [REMINDER] User %s, only 2 minutes remain "
                    "until your ticket reservation "
                    "(Reservation: %s) expires. Please complete "
                    "the payment!"
                )
                logger.info(reminder_msg, user_id, reservation_id)
    except Exception as e:
        logger.error(
            "Error occurred while processing background task: %s",
            str(e),
        )


@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary=("Reserve a ticket with 15-min lock and background reminder"),
)
def reserve_ticket(
    data: ReservationRequest,
    background_tasks: BackgroundTasks,
    user_id: int = Depends(get_current_user_id),
):
    try:
        with get_db_cursor() as cursor:
            # 1. Check ticket availability
            cursor.execute(
                (
                    "SELECT remaining_capacity "
                    "FROM tickets "
                    "WHERE ticket_id = %s "
                    "FOR UPDATE;"
                ),
                (data.ticket_id,),
            )
            ticket = cursor.fetchone()

            if not ticket:
                raise HTTPException(
                    status_code=404,
                    detail="Ticket not found",
                )

            if ticket["remaining_capacity"] < 1:
                raise HTTPException(
                    status_code=400,
                    detail="Ticket is sold out",
                )

            cursor.execute(
                (
                    "SELECT reservation_id "
                    "FROM reservations "
                    "WHERE user_id = %s "
                    "AND ticket_id = %s "
                    "AND status IN ('pending', 'paid');"
                ),
                (user_id, data.ticket_id),
            )
            if cursor.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "You already have an active reservation "
                        "for this ticket"
                    ),
                )

            cursor.execute(
                """
                UPDATE tickets
                SET remaining_capacity = remaining_capacity - 1
                WHERE ticket_id = %s;
                """,
                (data.ticket_id,),
            )

            insert_query = (
                "INSERT INTO reservations "
                "(user_id, ticket_id, status, expires_at) "
                "VALUES (%s, %s, 'pending', "
                "NOW() + INTERVAL '15 minutes') "
                "RETURNING reservation_id, expires_at;"
            )
            cursor.execute(insert_query, (user_id, data.ticket_id))
            reservation = cursor.fetchone()

            cursor.connection.commit()
            clear_ticket_cache()

            background_tasks.add_task(
                expiration_reminder_task,
                reservation["reservation_id"],
                user_id,
            )

            return {
                "reservation_id": reservation["reservation_id"],
                "ticket_id": data.ticket_id,
                "status": "pending",
                "message": (
                    "Ticket successfully reserved for 15 minutes. "
                    "Reminder will be sent 2 mins before expiry."
                ),
                "expires_at": reservation["expires_at"],
            }

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )
