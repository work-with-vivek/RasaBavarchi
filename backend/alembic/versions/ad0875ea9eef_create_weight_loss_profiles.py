"""create weight loss profiles

Revision ID: ad0875ea9eef
Revises: 8549a631868a
Create Date: 2026-09-11 13:16:34.365158

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "ad0875ea9eef"
down_revision: Union[str, Sequence[str], None] = "8549a631868a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create the weight loss profiles table."""

    op.create_table(
        "weight_loss_profiles",
        sa.Column(
            "id",
            sa.UUID(),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.UUID(),
            nullable=False,
        ),
        sa.Column(
            "age",
            sa.Integer(),
            nullable=False,
        ),
        sa.Column(
            "gender",
            sa.String(length=20),
            nullable=False,
        ),
        sa.Column(
            "height_cm",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "weight_kg",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "activity_level",
            sa.String(length=30),
            nullable=False,
        ),
        sa.Column(
            "goal_weight_kg",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        "ix_weight_loss_profiles_user_id",
        "weight_loss_profiles",
        ["user_id"],
        unique=True,
    )


def downgrade() -> None:
    """Drop the weight loss profiles table."""

    op.drop_index(
        "ix_weight_loss_profiles_user_id",
        table_name="weight_loss_profiles",
    )

    op.drop_table("weight_loss_profiles")