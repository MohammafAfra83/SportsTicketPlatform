from fastapi import APIRouter, HTTPException, Query, Path, status
import json
from app.database import get_db_cursor
from app.redis_client import redis_client
from app.schemas.tickets import TicketDetailResponse, TicketListResponse

router = APIRouter(prefix="/api/tickets", tags=["Tickets"])


@router.get(
    "/search",
    response_model=TicketListResponse,
    status_code=status.HTTP_200_OK,
    summary="Advanced Ticket Search with Smart Redis Caching",
)
def search_tickets(
    sport_type: str | None = Query(
        None,
        description="Sport type: football, volleyball, basketball",
    ),
    venue: str | None = Query(None, description="Name of the venue/stadium"),
    min_price: float | None = Query(
        None,
        ge=0,
        description="Minimum ticket price",
    ),
    max_price: float | None = Query(
        None,
        ge=0,
        description="Maximum ticket price",
    ),
    team_name: str | None = Query(
        None, description="Search by team name (home or away)"
    ),
    ticket_tier: str | None = Query(
        None, description="Ticket tier: VIP, Normal, Premium"
    ),
    start_date: str | None = Query(
        None, description="Matches starting from date (YYYY-MM-DD)"
    ),
):
    cache_key = (
        f"tickets:search:{sport_type or 'all'}:{venue or 'all'}:"
        f"{min_price or '0'}:{max_price or 'inf'}:"
        f"{team_name or 'all'}:{ticket_tier or 'all'}:"
        f"{start_date or 'all'}"
    )
    cached_data = redis_client.get(cache_key)
    if cached_data:
        return {
            "source": "cache (Redis) ⚡",
            "count": len(json.loads(cached_data)),
            "tickets": json.loads(cached_data),
        }

    try:
        with get_db_cursor() as cursor:
            query = "SELECT * FROM tickets WHERE is_active = TRUE"
            params = []
            if sport_type:
                query += " AND sport_type = %s"
                params.append(sport_type)
            if venue:
                query += " AND venue_name ILIKE %s"
                params.append(f"%{venue}%")
            if min_price is not None:
                query += " AND price >= %s"
                params.append(min_price)
            if max_price is not None:
                query += " AND price <= %s"
                params.append(max_price)
            if team_name:
                query += " AND (home_team ILIKE %s OR away_team ILIKE %s)"
                params.append(f"%{team_name}%")
                params.append(f"%{team_name}%")
            if ticket_tier:
                query += " AND ticket_tier ILIKE %s"
                params.append(f"%{ticket_tier}%")
            if start_date:
                query += " AND match_date >= %s::timestamp"
                params.append(start_date)

            query += " ORDER BY match_date ASC;"
            cursor.execute(query, tuple(params))

            tickets_list = []
            for row in cursor.fetchall():
                item = dict(row)
                item["match_date"] = item["match_date"].isoformat()
                item["price"] = float(item["price"])
                item["title"] = f"{item['home_team']} vs {item['away_team']}"
                tickets_list.append(item)

            redis_client.set(cache_key, json.dumps(tickets_list), ex=60)
            return {
                "source": "database (PostgreSQL) 🐘",
                "count": len(tickets_list),
                "tickets": tickets_list,
            }
    except Exception as e:
        detail = f"Database error: {str(e)}"
        raise HTTPException(
            status_code=500,
            detail=detail,
        )


@router.get(
    "/{ticket_id}",
    response_model=TicketDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get ticket details with JOINs and COALESCE",
)
def get_ticket_details(
    ticket_id: int = Path(..., gt=0, description="The ID of the ticket")
):
    try:
        with get_db_cursor() as cursor:
            query = """
SELECT t.*,
    COALESCE(
        f.league_name,
        v.league_name,
        b.league_name
    ) AS league_name,
    COALESCE(
        f.stadium_name,
        v.hall_name,
        b.hall_name
    ) AS facility_name,
    COALESCE(
        f.stand_section,
        v.seat_section,
        b.seat_section
    ) AS seat_section,
    COALESCE(
        f.row_number,
        v.row_number,
        b.row_number
    ) AS row_number,
    COALESCE(
        f.seat_number,
        v.seat_number,
        b.seat_number
    ) AS seat_number,
    COALESCE(
        f.ticket_type,
        v.ticket_tier,
        b.ticket_tier
    ) AS specific_ticket_tier,
    COALESCE(
        f.amenities,
        v.amenities,
        b.amenities
    ) AS amenities
FROM tickets t
LEFT JOIN football_details f ON t.ticket_id = f.ticket_id
LEFT JOIN volleyball_details v ON t.ticket_id = v.ticket_id
LEFT JOIN basketball_details b ON t.ticket_id = b.ticket_id
WHERE t.ticket_id = %s;
            """
            cursor.execute(query, (ticket_id,))
            row = cursor.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Ticket not found")

            item = dict(row)
            item["match_date"] = item["match_date"].isoformat()
            item["price"] = float(item["price"])
            item["title"] = f"{item['home_team']} vs {item['away_team']}"
            return item
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        detail = f"Database error: {str(e)}"
        raise HTTPException(
            status_code=500,
            detail=detail,
        )
