"""add login lock fields

Revision ID: 0b1145c13aa5
Revises: 07d1b322ec3c
Create Date: 2026-09-14 12:54:18.317011

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "0b1145c13aa5"
down_revision: Union[str, Sequence[str], None] = "07d1b322ec3c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add temporary login lock fields to users."""

    op.add_column(
        "users",
        sa.Column(
            "failed_login_attempts",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
    )

    op.add_column(
        "users",
        sa.Column(
            "locked_until",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )


def downgrade() -> None:
    """Remove temporary login lock fields from users."""

    op.drop_column(
        "users",
        "locked_until",
    )

    op.drop_column(
        "users",
        "failed_login_attempts",
    )