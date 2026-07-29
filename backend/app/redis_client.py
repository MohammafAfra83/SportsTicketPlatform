import redis
from app.config import settings

# Connecting to the Redis cache. Use decode_responses to receive
# text instead of bytes.
try:
    redis_client = redis.Redis(
        host=settings.REDIS_HOST,
        port=settings.REDIS_PORT,
        db=settings.REDIS_DB,
        decode_responses=True,
    )
    print("✅ Redis Client initialized successfully.")
except Exception as e:
    print(f"❌ Error initializing Redis: {e}")
    redis_client = None


def check_redis_connection():
    """Check the connection to the Redis server"""
    try:
        return redis_client.ping()
    except Exception:
        return False
