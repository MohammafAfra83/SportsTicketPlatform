from fastapi import APIRouter, HTTPException, status, Depends
from app.schemas.payments import PaymentRequest, PaymentResponse
from app.schemas.tickets import CancelTicketRequest
from app.database import get_db_cursor
from app.routes.reservations import get_current_user_id
from app.redis_client import clear_ticket_cache
from datetime import datetime

router = APIRouter(prefix="/api/payments", tags=["Payments"])


@router.post(
    "/",
    response_model=PaymentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Process payment for a pending reservation",
)
def process_payment(
    data: PaymentRequest,
    user_id: int = Depends(get_current_user_id),
):
    try:
        with get_db_cursor() as cursor:
            # 1. Lock the reservation row for update
            cursor.execute(
                """
                SELECT r.reservation_id,
                       r.status,
                       r.expires_at,
                       (r.expires_at < NOW()) AS is_expired,
                       t.price,
                       t.ticket_id
                FROM reservations r
                JOIN tickets t ON r.ticket_id = t.ticket_id
                WHERE r.reservation_id = %s
                  AND r.user_id = %s
                FOR UPDATE OF r;
                """,
                (data.reservation_id, user_id),
            )

            reservation = cursor.fetchone()

            if not reservation:
                raise HTTPException(
                    status_code=404,
                    detail=("Reservation not found or does not belong to you"),
                )

            if reservation["status"] == "paid":
                raise HTTPException(
                    status_code=400,
                    detail="Reservation is already paid",
                )

            if reservation["status"] == "cancelled":
                raise HTTPException(
                    status_code=400,
                    detail="Reservation has been cancelled",
                )

            # 2. Check for Expiration (The 15-minute rule)
            if reservation["is_expired"]:
                # Revert capacity and cancel reservation
                cursor.execute(
                    (
                        "UPDATE reservations SET status = 'cancelled' "
                        "WHERE reservation_id = %s;"
                    ),
                    (data.reservation_id,),
                )
                cursor.execute(
                    (
                        "UPDATE tickets "
                        "SET remaining_capacity = remaining_capacity + 1 "
                        "WHERE ticket_id = %s;"
                    ),
                    (reservation["ticket_id"],),
                )
                cursor.connection.commit()
                clear_ticket_cache()  # Invalidate cache
                raise HTTPException(
                    status_code=400,
                    detail="Reservation expired. Ticket returned to the pool.",
                )

            # 3. Process the payment
            cursor.execute(
                """
                INSERT INTO payments (
                    reservation_id,
                    user_id,
                    amount,
                    payment_method,
                    status,
                    paid_at
                )
                VALUES (%s, %s, %s, %s, 'successful', NOW())
                RETURNING payment_id, paid_at;
                """,
                (
                    data.reservation_id,
                    user_id,
                    reservation["price"],
                    data.payment_method,
                ),
            )

            payment = cursor.fetchone()

            # 4. Update reservation status to paid
            cursor.execute(
                (
                    "UPDATE reservations "
                    "SET status = 'paid' "
                    "WHERE reservation_id = %s;"
                ),
                (data.reservation_id,),
            )

            cursor.connection.commit()

            return {
                "payment_id": payment["payment_id"],
                "reservation_id": data.reservation_id,
                "amount": float(reservation["price"]),
                "status": "successful",
                "message": "Payment completed successfully. Ticket issued.",
                "paid_at": payment["paid_at"],
            }

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        error_detail = f"Database error: {str(e)}"
        raise HTTPException(status_code=500, detail=error_detail)


@router.get(
    "/cancellation-penalty/{reservation_id}",
    status_code=status.HTTP_200_OK,
    summary="Calculate penalty for cancelling a ticket",
)
def calculate_cancellation_penalty(
    reservation_id: int, user_id: int = Depends(get_current_user_id)
):
    try:
        with get_db_cursor() as cursor:
            # Fetch reservation and ticket details
            cursor.execute(
                (
                    "SELECT r.status, t.match_date, t.price\n"
                    "FROM reservations r\n"
                    "JOIN tickets t ON r.ticket_id = t.ticket_id\n"
                    "WHERE r.reservation_id = %s\n"
                    "  AND r.user_id = %s;"
                ),
                (reservation_id, user_id),
            )

            data = cursor.fetchone()
            if not data:
                raise HTTPException(
                    status_code=404,
                    detail="Reservation not found",
                )
            if data["status"] != "paid":
                raise HTTPException(
                    status_code=400,
                    detail="Only 'paid' reservations can be cancelled",
                )

            # Calculate time difference
            match_date = data["match_date"]
            # Ensure we are comparing timezone-aware or naive datetimes
            # correctly. Assuming match_date from DB is naive, we use
            # datetime.now()
            now = datetime.now()

            if match_date <= now:
                raise HTTPException(
                    status_code=400,
                    detail=("Match has already started or finished. Cannot " "cancel."),
                )

            time_diff = match_date - now
            hours_until_match = time_diff.total_seconds() / 3600

            # Determine Penalty Rules
            penalty_percentage = 0
            if hours_until_match < 24:
                penalty_percentage = 50
            elif 24 <= hours_until_match <= 72:
                penalty_percentage = 20
            else:
                penalty_percentage = 0

            price = float(data["price"])
            penalty_amount = price * (penalty_percentage / 100)
            refund_amount = price - penalty_amount

            return {
                "reservation_id": reservation_id,
                "match_date": match_date.isoformat(),
                "hours_until_match": round(hours_until_match, 2),
                "penalty_percentage": penalty_percentage,
                "penalty_amount": penalty_amount,
                "refund_amount": refund_amount,
            }

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        error_detail = f"Database error: {str(e)}"
        raise HTTPException(status_code=500, detail=error_detail)


@router.post(
    "/cancel",
    status_code=status.HTTP_200_OK,
    summary="Cancel a paid reservation and process refund",
)
def cancel_ticket(
    request: CancelTicketRequest, user_id: int = Depends(get_current_user_id)
):
    reservation_id = request.reservation_id

    # First, run the penalty calculation logic to get exact amounts
    penalty_data = calculate_cancellation_penalty(reservation_id, user_id)

    try:
        with get_db_cursor() as cursor:
            # 1. Update reservation status to 'cancelled'
            cursor.execute(
                "UPDATE reservations SET status = 'cancelled' "
                "WHERE reservation_id = %s RETURNING ticket_id;",
                (reservation_id,),
            )
            ticket_id = cursor.fetchone()["ticket_id"]

            # 2. Revert ticket capacity
            cursor.execute(
                "UPDATE tickets SET remaining_capacity = "
                "remaining_capacity + 1 WHERE ticket_id = %s;",
                (ticket_id,),
            )

            # 3. The refund is processed virtually (We don't insert a new
            # row in 'payments' because 'amount' must be >= 0 and
            # 'reservation_id' is UNIQUE).

            cursor.connection.commit()

            # 4. Clear cache to reflect new capacity
            clear_ticket_cache()

            return {
                "message": "Ticket successfully cancelled.",
                "refund_amount": penalty_data["refund_amount"],
                "penalty_applied": penalty_data["penalty_amount"],
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )
