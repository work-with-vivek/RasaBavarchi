"""add recipe food type

Revision ID: cab4fdc43529
Revises: 20a09ab39b82
Create Date: 2026-08-29 01:28:16.203871

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "cab4fdc43529"
down_revision: Union[str, Sequence[str], None] = "20a09ab39b82"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add food type classification to recipes."""

    op.add_column(
        "recipes",
        sa.Column(
            "food_type",
            sa.String(length=20),
            nullable=False,
            server_default="UNKNOWN",
        ),
    )

    # Remove the temporary server default.
    # Existing recipes already receive UNKNOWN.
    # Future values will be supplied by the application.
    op.alter_column(
        "recipes",
        "food_type",
        server_default=None,
    )


def downgrade() -> None:
    """Remove recipe food type classification."""

    op.drop_column(
        "recipes",
        "food_type",
    )