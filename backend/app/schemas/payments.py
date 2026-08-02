from pydantic import BaseModel, Field
from datetime import datetime


class PaymentRequest(BaseModel):
    reservation_id: int = Field(..., gt=0)
    payment_method: str = Field(
        ...,
        min_length=1,
        description="Payment method used (e.g., credit_card)",
    )


class PaymentResponse(BaseModel):
    payment_id: int
    reservation_id: int
    amount: float
    status: str
    message: str
    paid_at: datetime
