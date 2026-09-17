from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1 import api_router
from app.core.config import settings
from app.core.exception_handlers import register_exception_handlers


# =============================================================
# PATHS
# =============================================================

BASE_DIR = Path(__file__).resolve().parent.parent
MEDIA_DIR = BASE_DIR / "media"


# =============================================================
# APP
# =============================================================

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
)

register_exception_handlers(app)


# =============================================================
# CORS
# =============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =============================================================
# STATIC MEDIA
# =============================================================

MEDIA_DIR.mkdir(
    parents=True,
    exist_ok=True,
)

app.mount(
    "/media",
    StaticFiles(directory=str(MEDIA_DIR)),
    name="media",
)


# =============================================================
# API ROUTES
# =============================================================

app.include_router(api_router)


# =============================================================
# HEALTH CHECK
# =============================================================

@app.get("/")
def health_check():
    return {
        "message": f"{settings.app_name} is running!",
        "environment": settings.app_env,
        "debug": settings.debug,
    }