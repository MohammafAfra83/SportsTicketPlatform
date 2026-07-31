from fastapi import (
    APIRouter,
    HTTPException,
    Query,
    status,
)

from app.schemas.tickets import (
    TicketListResponse,
    TicketDetailResponse,
)
from app.redis_client import redis_client
from app.database import get_db_cursor
import json

router = APIRouter(
    prefix="/api/tickets",
    tags=["Tickets"],
)


@router.get(
    "/search",
    response_model=TicketListResponse,
    status_code=status.HTTP_200_OK,
    summary="Search matches with smart Redis caching",
)
def search_tickets(
    sport_type: str | None = Query(
        None,
        description="Sport type: football, volleyball, basketball",
    ),
    venue: str | None = Query(
        None,
        description="Name of the venue/stadium",
    ),
):
    # 1. Define unique cache key
    cache_key = (
        f"tickets:search:{sport_type or 'all'}:"
        f"{venue or 'all'}"
    )

    # 2. Check for Cache Hit in Redis
    cached_data = redis_client.get(cache_key)
    if cached_data:
        tickets_list = json.loads(cached_data)
        return {
            "source": "cache (Redis) ⚡",
            "count": len(tickets_list),
            "tickets": tickets_list,
        }

    # 3. Cache Miss: Execute raw SQL query on PostgreSQL
    try:
        with get_db_cursor() as cursor:
            query = """
                SELECT
                    ticket_id,
                    sport_type,
                    home_team,
                    away_team,
                    venue_name,
                    city,
                    ticket_tier,
                    organizer,
                    match_date,
                    price,
                    remaining_capacity,
                    is_active
                FROM tickets
                WHERE is_active = TRUE
            """
            params = []

            if sport_type:
                query += " AND sport_type = %s"
                params.append(sport_type)

            if venue:
                query += " AND venue_name ILIKE %s"
                params.append(f"%{venue}%")

            query += " ORDER BY match_date ASC;"

            cursor.execute(query, tuple(params))
            rows = cursor.fetchall()

            # Format data for JSON serialization
            tickets_list = []
            for row in rows:
                item = dict(row)
                item["match_date"] = item["match_date"].isoformat()
                item["price"] = float(item["price"])
                # Dynamically generate the title
                item["title"] = (
                    f"{item['home_team']} vs {item['away_team']}"
                )
                tickets_list.append(item)

            # 4. Store the result in Redis with a 60-second TTL
            redis_client.set(
                cache_key,
                json.dumps(tickets_list),
                ex=60,
            )

            return {
                "source": "database (PostgreSQL) 🐘",
                "count": len(tickets_list),
                "tickets": tickets_list,
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )


@router.get(
    "/{ticket_id}",
    response_model=TicketDetailResponse,
    status_code=status.HTTP_200_OK,
    summary=(
        "Get specific ticket details with 3NF JOINs & COALESCE"
    ),
)
def get_ticket_details(ticket_id: int):
    try:
        with get_db_cursor() as cursor:
            # Magic of COALESCE: Merges 3NF tables into a clean
            # single response!
            query = """
                SELECT
                    t.ticket_id,
                    t.sport_type,
                    t.home_team,
                    t.away_team,
                    t.venue_name,
                    t.city,
                    t.ticket_tier,
                    t.organizer,
                    t.match_date,
                    t.price,
                    t.remaining_capacity,
                    t.is_active,
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
                LEFT JOIN football_details f
                    ON t.ticket_id = f.ticket_id
                LEFT JOIN volleyball_details v
                    ON t.ticket_id = v.ticket_id
                LEFT JOIN basketball_details b
                    ON t.ticket_id = b.ticket_id
                WHERE t.ticket_id = %s;
            """
            cursor.execute(query, (ticket_id,))
            row = cursor.fetchone()

            if not row:
                raise HTTPException(
                    status_code=404,
                    detail="Ticket not found",
                )

            # Format the data for JSON
            item = dict(row)
            item["match_date"] = item["match_date"].isoformat()
            item["price"] = float(item["price"])
            item["title"] = (
                f"{item['home_team']} vs {item['away_team']}"
            )

            return item

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}",
        )
