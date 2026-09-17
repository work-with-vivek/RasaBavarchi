"""add ingredient food type

Revision ID: 20a09ab39b82
Revises: ed44142c86d8
Create Date: 2026-08-28 23:56:30.524337

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "20a09ab39b82"
down_revision: Union[str, Sequence[str], None] = "ed44142c86d8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    op.add_column(
        "ingredients",
        sa.Column(
            "food_type",
            sa.String(length=20),
            nullable=False,
            server_default="UNKNOWN",
        ),
    )

    op.alter_column(
        "ingredients",
        "food_type",
        server_default=None,
    )


def downgrade() -> None:
    """Downgrade schema."""

    op.drop_column(
        "ingredients",
        "food_type",
    )