from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler

from app.core.limiter import limiter
from app.api.Routes import router

app = FastAPI(
    title="Interpretation API",
    description="Backend para interpretar salidas del modelo de clasificación usando Gemini.",
    version="0.1.0",
)

# Rate limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS — ajusta los orígenes cuando tengas la URL del frontend en producción
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: reemplazar con la URL real del frontend en producción
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/")
async def root():
    return {
        "status": "ok",
        "version": "0.1.0",
        "docs": "/docs",
        "endpoints": "/api/v1/health",
    }