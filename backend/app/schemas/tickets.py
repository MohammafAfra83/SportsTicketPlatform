from pydantic import BaseModel
from datetime import datetime


class TicketResponse(BaseModel):
    ticket_id: int
    title: str  # Generated dynamically in Python
    sport_type: str
    home_team: str
    away_team: str
    venue_name: str
    city: str
    ticket_tier: str
    organizer: str
    match_date: datetime
    price: float
    remaining_capacity: int
    is_active: bool


class TicketListResponse(BaseModel):
    source: str
    count: int
    tickets: list[TicketResponse]
