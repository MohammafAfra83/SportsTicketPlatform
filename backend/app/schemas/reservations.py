from pydantic import BaseModel, Field
from datetime import datetime


class ReservationRequest(BaseModel):
    ticket_id: int = Field(
        ..., gt=0, description="The ID of the ticket to reserve"
    )


class ReservationResponse(BaseModel):
    reservation_id: int
    ticket_id: int
    status: str
    message: str
    expires_at: datetime
