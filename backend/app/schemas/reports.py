from pydantic import BaseModel
from datetime import datetime


class ReportCreate(BaseModel):
    subject: str
    description: str


class ReportResponse(BaseModel):
    report_id: int
    user_id: int
    subject: str
    description: str
    status: str
    created_at: datetime
