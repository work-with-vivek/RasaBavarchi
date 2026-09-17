from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

master_engine = create_engine(
    settings.master_database_url,
    echo=settings.debug,
)

MasterSessionLocal = sessionmaker(
    bind=master_engine,
    autoflush=False,
    autocommit=False,
)


def get_master_db() -> Generator[Session, None, None]:
    db = MasterSessionLocal()

    try:
        yield db
    finally:
        db.close()