from fastapi import APIRouter, HTTPException, Query, status
from app.schemas.tickets import TicketListResponse
from app.redis_client import redis_client
from app.database import get_db_cursor
import json

router = APIRouter(prefix="/api/tickets", tags=["Tickets"])


@router.get(
    "/search",
    response_model=TicketListResponse,
    status_code=status.HTTP_200_OK,
    summary="Search matches with smart Redis caching",
)
def search_tickets(
    sport_type: str | None = Query(
        None, description="Sport type: football, volleyball, basketball"
    ),
    venue: str | None = Query(None, description="Name of the venue/stadium"),
):
    # 1. Define unique cache key
    cache_key = f"tickets:search:{sport_type or 'all'}:{venue or 'all'}"

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
                SELECT ticket_id, sport_type, home_team, away_team, 
                       venue_name, city, ticket_tier, organizer,
                       match_date, price, remaining_capacity, is_active
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
                item["title"] = f"{item['home_team']} vs {item['away_team']}"
                tickets_list.append(item)

            # 4. Store the result in Redis with a 60-second TTL
            redis_client.set(cache_key, json.dumps(tickets_list), ex=60)

            return {
                "source": "database (PostgreSQL) 🐘",
                "count": len(tickets_list),
                "tickets": tickets_list,
            }

    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Database error: {str(e)}"
        )
