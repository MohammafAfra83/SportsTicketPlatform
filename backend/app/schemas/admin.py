from pydantic import BaseModel


class DashboardStatsResponse(BaseModel):
    total_revenue: float
    total_tickets_sold: int
    total_cancellations: int
    pending_reports: int
