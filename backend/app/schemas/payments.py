from pydantic import BaseModel
from datetime import datetime


class PaymentRequest(BaseModel):
    reservation_id: int
    payment_method: str = "credit_card"


class PaymentResponse(BaseModel):
    payment_id: int
    reservation_id: int
    amount: float
    status: str
    message: str
    paid_at: datetime
