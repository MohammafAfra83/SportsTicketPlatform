from fastapi import APIRouter, HTTPException, status
from app.database import get_db_cursor

router = APIRouter(prefix="/api", tags=["Locations & Venues"])


@router.get(
    "/cities-venues",
    status_code=status.HTTP_200_OK,
    summary=(
        "Get unique list of cities and venues"
    ),
)
def get_cities_and_venues():
    try:
        with get_db_cursor() as cursor:
            # Query to fetch distinct cities and venue names from tickets table
            cursor.execute("""
                SELECT DISTINCT city, venue_name
                FROM tickets
                WHERE match_date > NOW()
                ORDER BY city, venue_name;
            """)
            return cursor.fetchall()

    except Exception as e:
        detail = f"Database error: {str(e)}"
        raise HTTPException(status_code=500, detail=detail)
