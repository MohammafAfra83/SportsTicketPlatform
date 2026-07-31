from fastapi import APIRouter, HTTPException, status, Depends
from app.schemas.admin import (
    DashboardStatsResponse,
    AdminManageRequest,
    AdminReservationResponse,
)
from app.database import get_db_cursor
from app.routes.reservations import get_current_user_id

router = APIRouter(prefix="/api/admin", tags=["Admin Dashboard"])


@router.get(
    "/dashboard-stats",
    response_model=DashboardStatsResponse,
    status_code=status.HTTP_200_OK,
    summary=("Get aggregated statistics for the admin dashboard"),
)
def get_dashboard_statistics(
    _user_id: int = Depends(get_current_user_id),
):
    # Note: In a production environment, you would check
    # if the user's role is 'admin' here.
    try:
        with get_db_cursor() as cursor:
            # Using subqueries to get all statistics in a single
            # database hit
            sql = (
                "SELECT "
                "(SELECT COALESCE(SUM(amount), 0) FROM payments "
                "WHERE status = 'successful' AND amount > 0) "
                "AS total_revenue, "
                "(SELECT COUNT(*) FROM payments "
                "WHERE status = 'successful' AND amount > 0) "
                "AS total_tickets_sold, "
                "(SELECT COUNT(*) FROM reservations "
                "WHERE status = 'cancelled') "
                "AS total_cancellations, "
                "(SELECT COUNT(*) FROM reports "
                "WHERE status = 'under_review') "
                "AS pending_reports;"
            )
            cursor.execute(sql)

            stats = cursor.fetchone()
            return stats

    except Exception:
        raise HTTPException(
            status_code=400,
            detail=("Invalid entity type. Use 'report' or 'reservation'."),
        )


@router.get(
    "/tickets",
    response_model=list[AdminReservationResponse],
    status_code=status.HTTP_200_OK,
    summary="View all reservations and suspicious transactions(Support/Admin)",
)
def get_all_reservations(user_id: int = Depends(get_current_user_id)):
    try:
        with get_db_cursor() as cursor:
            # Access check: Only 'support' and 'admin' roles are permitted.
            cursor.execute(
                "SELECT role FROM users WHERE user_id = %s",
                (user_id,),
            )
            user = cursor.fetchone()
            if not user or user["role"] not in ["support", "admin"]:
                raise HTTPException(
                    status_code=403,
                    detail="Access denied. Support or Admin role required.",
                )

            # Build query to show user, reservation, match, and
            # payment details
            query = (
                "SELECT\n"
                "  r.reservation_id,\n"
                "  r.user_id,\n"
                "  u.first_name,\n"
                "  u.last_name,\n"
                "  u.phone_number,\n"
                "  r.ticket_id,\n"
                "  t.venue_name,\n"
                "  t.match_date,\n"
                "  r.status,\n"
                "  p.amount AS payment_amount\n"
                "FROM reservations r\n"
                "JOIN users u ON r.user_id = u.user_id\n"
                "JOIN tickets t ON r.ticket_id = t.ticket_id\n"
                "LEFT JOIN payments p ON r.reservation_id = "
                "p.reservation_id\n"
                "ORDER BY r.created_at DESC\n"
                "LIMIT 100;",
            )
            cursor.execute(query)
            return cursor.fetchall()

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        detail = f"Database error: {str(e)}"
        raise HTTPException(status_code=500, detail=detail)


@router.put(
    "/manage",
    status_code=status.HTTP_200_OK,
    summary="Change status of reports or cancel/approve reservations",
)
def manage_entity(
    data: AdminManageRequest, user_id: int = Depends(get_current_user_id)
):
    try:
        with get_db_cursor() as cursor:
            # Access check: Only 'support' and 'admin' roles are permitted.
            cursor.execute(
                "SELECT role FROM users WHERE user_id = %s",
                (user_id,),
            )
            user = cursor.fetchone()
            if not user or user["role"] not in ["support", "admin"]:
                raise HTTPException(
                    status_code=403,
                    detail="Access denied. Support or Admin role required.",
                )

            # Dynamic logic: Update table based on the type of entity sent
            if data.entity_type == "report":
                cursor.execute(
                    "UPDATE reports SET status = %s "
                    "WHERE report_id = %s RETURNING report_id;",
                    (data.new_status, data.entity_id),
                )
            elif data.entity_type == "reservation":
                cursor.execute(
                    "UPDATE reservations SET status = %s "
                    "WHERE reservation_id = %s RETURNING reservation_id;",
                    (data.new_status, data.entity_id),
                )
            else:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "Invalid entity type. Use 'report' or "
                        "'reservation'."
                    ),
                )

            if not cursor.fetchone():
                raise HTTPException(
                    status_code=404,
                    detail=(f"{data.entity_type} not found in " "database."),
                )

            cursor.connection.commit()
            message = (
                f"{data.entity_type.capitalize()} status updated to "
                f"'{data.new_status}' successfully."
            )
            return {"message": message}

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        # Wrap long line to satisfy line-length limit
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )
