from pydantic import BaseModel
from datetime import datetime


class ReportCreate(BaseModel):
    category: str
    report_text: str
    ticket_id: int | None = None
    reservation_id: int | None = None


class ReportResponse(BaseModel):
    report_id: int
    user_id: int
    ticket_id: int | None = None
    reservation_id: int | None = None
    category: str
    report_text: str
    status: str
    created_at: datetime
