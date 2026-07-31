from fastapi import APIRouter, HTTPException, status, Depends
from app.schemas.admin import DashboardStatsResponse
from app.database import get_db_cursor
from app.routes.reservations import get_current_user_id

router = APIRouter(prefix="/api/admin", tags=["Admin Dashboard"])


@router.get(
    "/dashboard-stats",
    response_model=DashboardStatsResponse,
    status_code=status.HTTP_200_OK,
    summary=(
        "Get aggregated statistics for the admin dashboard"
    ),
)
def get_dashboard_statistics(
    user_id: int = Depends(get_current_user_id),
):
    # Note: In a production environment, you would check
    # if the user's role is 'admin' here.
    try:
        with get_db_cursor() as cursor:
            # Using subqueries to get all statistics in a single
            # database hit
            cursor.execute(
                """
                SELECT
                    (SELECT COALESCE(
                         SUM(amount), 0
                     )
                     FROM payments
                     WHERE status = 'successful'
                       AND amount > 0
                    ) AS total_revenue,
                    (SELECT COUNT(*)
                     FROM payments
                     WHERE status = 'successful'
                       AND amount > 0
                    ) AS total_tickets_sold,
                    (SELECT COUNT(*)
                     FROM reservations
                     WHERE status = 'cancelled'
                    ) AS total_cancellations,
                    (SELECT COUNT(*)
                     FROM reports
                     WHERE status = 'under_review'
                    ) AS pending_reports;
                """
            )

            stats = cursor.fetchone()
            return stats

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )
