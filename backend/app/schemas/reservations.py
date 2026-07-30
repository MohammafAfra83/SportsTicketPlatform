from pydantic import BaseModel
from datetime import datetime


class ReservationRequest(BaseModel):
    ticket_id: int


class ReservationResponse(BaseModel):
    reservation_id: int
    ticket_id: int
    status: str
    message: str
    expires_at: datetime
