from pydantic import BaseModel, Field
from typing import Optional


# ── Requests ──────────────────────────────────────────────

class MetaPersonalizadaRequest(BaseModel):
    ticket_objetivo: float = Field(
        ..., gt=0,
        description="Ticket promedio objetivo que quiere alcanzar el negocio",
        examples=[4500.0]
    )


# ── Response base ─────────────────────────────────────────

class InterpretacionResponse(BaseModel):
    modulo: str
    interpretacion: str
    datos: dict


class MetaPersonalizadaResponse(BaseModel):
    ticket_actual: float
    ticket_objetivo: float
    incremento_pct: float
    advertencia: Optional[str]
    interpretacion: str