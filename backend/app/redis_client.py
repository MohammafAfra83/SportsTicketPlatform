import redis
from app.config import settings
import random

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


def clear_ticket_cache():
    """Delete cached ticket search queries from Redis.
    This ensures stale search results are not served from cache.
    """
    try:
        # Scan and delete all keys matching the ticket search pattern
        for key in redis_client.scan_iter("tickets:search:*"):
            redis_client.delete(key)
    except Exception as e:
        print(f"Redis cache clearing error: {e}")


# redis_client = redis.Redis(...)


def generate_and_set_otp(phone_number: str) -> str:
    """Generate a random 6-digit code and store it in Redis.

    The code expires after 120 seconds.
    """
    otp_code = str(random.randint(100000, 999999))
    redis_key = f"otp:{phone_number}"

    redis_client.setex(redis_key, 120, otp_code)
    return otp_code


def verify_otp(phone_number: str, user_otp: str) -> bool:
    """Verifying the entered code using Redis cache"""
    redis_key = f"otp:{phone_number}"
    stored_otp = redis_client.get(redis_key)

    if stored_otp and stored_otp == user_otp:
        # For preventing reuse, delete the code after successful
        # verification (Invalidation)
        redis_client.delete(redis_key)
        return True
    return False


def invalidate_user_profile_cache(user_id: int):
    """Clearing the user profile cache when editing information"""
    redis_key = f"user:profile:{user_id}"
    redis_client.delete(redis_key)
