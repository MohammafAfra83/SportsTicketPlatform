from fastapi import APIRouter, HTTPException, status, Depends
from app.schemas.users import BookingResponse, UserProfileUpdate
from app.database import get_db_cursor
from app.routes.reservations import get_current_user_id
from app.redis_client import invalidate_user_profile_cache

router = APIRouter(prefix="/api/user", tags=["User Profile"])


@router.get(
    "/bookings",
    response_model=list[BookingResponse],
    status_code=status.HTTP_200_OK,
    summary="Get booking history for the current user",
)
def get_user_bookings(user_id: int = Depends(get_current_user_id)):
    try:
        with get_db_cursor() as cursor:
            query = """
                SELECT
                    r.reservation_id,
                    r.ticket_id,
                    t.home_team,
                    t.away_team,
                    t.match_date,
                    r.status AS reservation_status,
                    p.status AS payment_status,
                    p.amount AS amount_paid,
                    r.reserved_at
                FROM reservations r
                JOIN tickets t ON r.ticket_id = t.ticket_id
                LEFT JOIN payments p ON r.reservation_id = p.reservation_id
                WHERE r.user_id = %s
                ORDER BY r.reserved_at DESC;
            """
            cursor.execute(query, (user_id,))
            rows = cursor.fetchall()

            bookings = []
            for row in rows:
                bookings.append(
                    {
                        "reservation_id": row["reservation_id"],
                        "ticket_id": row["ticket_id"],
                        "home_team": row["home_team"],
                        "away_team": row["away_team"],
                        "match_date": row["match_date"],
                        "reservation_status": row["reservation_status"],
                        "payment_status": row["payment_status"],
                        "amount_paid": (
                            float(row["amount_paid"])
                            if row["amount_paid"]
                            else None
                        ),
                        "reserved_at": row["reserved_at"],
                    }
                )

            return bookings

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )


@router.put(
    "/profile",
    status_code=status.HTTP_200_OK,
    summary="Update user profile and invalidate cache",
)
def update_profile(
    data: UserProfileUpdate,
    user_id: int = Depends(get_current_user_id),
):
    try:
        with get_db_cursor() as cursor:
            # Build an UPDATE query only for fields that are provided
            updates = []
            params = []

            if data.first_name:
                updates.append("first_name = %s")
                params.append(data.first_name)
            if data.last_name:
                updates.append("last_name = %s")
                params.append(data.last_name)
            if data.city:
                updates.append("city = %s")
                params.append(data.city)

            if not updates:
                raise HTTPException(
                    status_code=400, detail="No data provided to update"
                )

            set_clause = ", ".join(updates)
            query = (
                "UPDATE users SET "
                f"{set_clause} "
                "WHERE user_id = %s"
            )
            params.append(user_id)

            cursor.execute(query, tuple(params))
            cursor.connection.commit()

            # Dynamically invalidate the user profile cache
            invalidate_user_profile_cache(user_id)

            return {
                "message": "Profile updated successfully. Cache invalidated."
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )
