from pydantic import BaseModel
from datetime import datetime


class BookingResponse(BaseModel):
    reservation_id: int
    ticket_id: int
    home_team: str
    away_team: str
    match_date: datetime
    reservation_status: str
    payment_status: str | None
    amount_paid: float | None
    reserved_at: datetime


class UserProfileUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    city: str | None = None
