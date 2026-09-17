"""create email otp table

Revision ID: c4424843f3c2
Revises: 0b1145c13aa5
Create Date: 2026-09-14 16:07:20.002275

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c4424843f3c2"
down_revision: Union[str, Sequence[str], None] = "0b1145c13aa5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "email_otps",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("purpose", sa.String(length=30), nullable=False),
        sa.Column("otp_hash", sa.String(length=255), nullable=False),
        sa.Column(
            "expires_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "attempts",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
        sa.Column(
            "is_used",
            sa.Boolean(),
            server_default="false",
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
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        "ix_email_otps_email",
        "email_otps",
        ["email"],
        unique=False,
    )

    op.create_index(
        "ix_email_otps_expires_at",
        "email_otps",
        ["expires_at"],
        unique=False,
    )

    op.create_index(
        "ix_email_otps_purpose",
        "email_otps",
        ["purpose"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_email_otps_purpose",
        table_name="email_otps",
    )

    op.drop_index(
        "ix_email_otps_expires_at",
        table_name="email_otps",
    )

    op.drop_index(
        "ix_email_otps_email",
        table_name="email_otps",
    )

    op.drop_table("email_otps")