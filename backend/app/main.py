from fastapi import FastAPI
from app.config import settings
from app.redis_client import check_redis_connection
from app.database import get_db_cursor

app = FastAPI(
    title=settings.APP_NAME,
    version="3.0.0",
    description="SportsTicketPlatform API - Phase 3 (Raw SQL & Redis Cache)",
)


@app.get("/")
def health_check():
    # Checking Redis Connection
    redis_status = check_redis_connection()

    # Checking PostgreSQL Connection with Raw Query
    db_status = False
    try:
        with get_db_cursor() as cursor:
            cursor.execute("SELECT 1 AS status;")
            result = cursor.fetchone()
            if result and result["status"] == 1:
                db_status = True
    except Exception as e:
        print(f"DB Check Error: {e}")

    return {
        "app_name": settings.APP_NAME,
        "database_connected": db_status,
        "redis_connected": redis_status,
        "orm_used": False,
        "message": "Welcome to SportsTicketPlatform Backend!",
    }
