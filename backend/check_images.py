from sqlalchemy import text

from app.dependencies.database import SessionLocal


db = SessionLocal()

try:
    rows = db.execute(
        text(
            """
            SELECT external_id, title, image_url
            FROM recipes
            WHERE image_url IS NOT NULL
              AND TRIM(image_url) <> ''
            LIMIT 5
            """
        )
    ).fetchall()

    for row in rows:
        print(row)

finally:
    db.close()