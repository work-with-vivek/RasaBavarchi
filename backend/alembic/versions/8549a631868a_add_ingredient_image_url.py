"""add ingredient image url

Revision ID: 8549a631868a
Revises: f4093c322b6e
Create Date: 2026-09-01 12:50:49.963660

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "8549a631868a"
down_revision: Union[str, Sequence[str], None] = "f4093c322b6e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add image URL to ingredients."""

    op.add_column(
        "ingredients",
        sa.Column(
            "image_url",
            sa.String(length=500),
            nullable=True,
        ),
    )


def downgrade() -> None:
    """Remove image URL from ingredients."""

    op.drop_column(
        "ingredients",
        "image_url",
    )