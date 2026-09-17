"""add ingredient classification knowledge base

Revision ID: add_ingredient_classification_knowledge_base
Revises:
Create Date: 2026-08-29
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# ---------------------------------------------------------------------------
# Revision identifiers
# ---------------------------------------------------------------------------

revision: str = "f4093c322b6e"
down_revision: Union[str, Sequence[str], None] = "cab4fdc43529"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# ---------------------------------------------------------------------------
# Upgrade
# ---------------------------------------------------------------------------


def upgrade() -> None:
    # ========================================================================
    # 1. ingredient_families
    # ========================================================================

    op.create_table(
        "ingredient_families",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "name",
            sa.String(150),
            nullable=False,
        ),
        sa.Column(
            "description",
            sa.Text(),
            nullable=True,
        ),
        sa.Column(
            "default_food_type",
            sa.String(30),
            nullable=False,
            server_default="UNKNOWN",
        ),
        sa.Column(
            "default_confidence",
            sa.Numeric(5, 4),
            nullable=False,
            server_default="0.0000",
        ),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.UniqueConstraint(
            "name",
            name="uq_ingredient_families_name",
        ),
        sa.CheckConstraint(
            "default_food_type IN "
            "('VEGAN', 'VEGETARIAN', 'NON_VEGETARIAN', 'UNKNOWN')",
            name="ck_ingredient_families_food_type",
        ),
        sa.CheckConstraint(
            "default_confidence >= 0.0000 "
            "AND default_confidence <= 1.0000",
            name="ck_ingredient_families_confidence",
        ),
    )

    op.create_index(
        "ix_ingredient_families_name",
        "ingredient_families",
        ["name"],
        unique=False,
    )

    op.create_index(
        "ix_ingredient_families_food_type",
        "ingredient_families",
        ["default_food_type"],
        unique=False,
    )

    # ========================================================================
    # 2. ingredient_rules
    # ========================================================================

    op.create_table(
        "ingredient_rules",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "family_id",
            postgresql.UUID(as_uuid=True),
            nullable=True,
        ),
        sa.Column(
            "pattern",
            sa.String(255),
            nullable=False,
        ),
        sa.Column(
            "match_type",
            sa.String(30),
            nullable=False,
        ),
        sa.Column(
            "food_type",
            sa.String(30),
            nullable=False,
        ),
        sa.Column(
            "priority",
            sa.Integer(),
            nullable=False,
            server_default="100",
        ),
        sa.Column(
            "confidence",
            sa.Numeric(5, 4),
            nullable=False,
            server_default="0.0000",
        ),
        sa.Column(
            "reason",
            sa.Text(),
            nullable=True,
        ),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(
            ["family_id"],
            ["ingredient_families.id"],
            name="fk_ingredient_rules_family_id",
            ondelete="SET NULL",
        ),
        sa.CheckConstraint(
            "match_type IN "
            "('EXACT', 'PREFIX', 'CONTAINS', 'SUFFIX', 'REGEX')",
            name="ck_ingredient_rules_match_type",
        ),
        sa.CheckConstraint(
            "food_type IN "
            "('VEGAN', 'VEGETARIAN', 'NON_VEGETARIAN', 'UNKNOWN')",
            name="ck_ingredient_rules_food_type",
        ),
        sa.CheckConstraint(
            "confidence >= 0.0000 "
            "AND confidence <= 1.0000",
            name="ck_ingredient_rules_confidence",
        ),
    )

    op.create_index(
        "ix_ingredient_rules_family_id",
        "ingredient_rules",
        ["family_id"],
        unique=False,
    )

    op.create_index(
        "ix_ingredient_rules_pattern",
        "ingredient_rules",
        ["pattern"],
        unique=False,
    )

    op.create_index(
        "ix_ingredient_rules_food_type",
        "ingredient_rules",
        ["food_type"],
        unique=False,
    )

    op.create_index(
        "ix_ingredient_rules_priority",
        "ingredient_rules",
        ["priority"],
        unique=False,
    )

    # ========================================================================
    # 3. ingredient_classifications
    # ========================================================================

    op.create_table(
        "ingredient_classifications",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "ingredient_id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
        ),
        sa.Column(
            "food_type",
            sa.String(30),
            nullable=False,
            server_default="UNKNOWN",
        ),
        sa.Column(
            "confidence",
            sa.Numeric(5, 4),
            nullable=False,
            server_default="0.0000",
        ),
        sa.Column(
            "method",
            sa.String(50),
            nullable=False,
        ),
        sa.Column(
            "reason",
            sa.Text(),
            nullable=True,
        ),
        sa.Column(
            "source",
            sa.String(100),
            nullable=False,
            server_default="RasaBavarchi",
        ),
        sa.Column(
            "reviewed",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(
            ["ingredient_id"],
            ["ingredients.id"],
            name="fk_ingredient_classifications_ingredient_id",
            ondelete="CASCADE",
        ),
        sa.UniqueConstraint(
            "ingredient_id",
            name="uq_ingredient_classifications_ingredient_id",
        ),
        sa.CheckConstraint(
            "food_type IN "
            "('VEGAN', 'VEGETARIAN', 'NON_VEGETARIAN', 'UNKNOWN')",
            name="ck_ingredient_classifications_food_type",
        ),
        sa.CheckConstraint(
            "confidence >= 0.0000 "
            "AND confidence <= 1.0000",
            name="ck_ingredient_classifications_confidence",
        ),
    )

    op.create_index(
        "ix_ingredient_classifications_ingredient_id",
        "ingredient_classifications",
        ["ingredient_id"],
        unique=True,
    )

    op.create_index(
        "ix_ingredient_classifications_food_type",
        "ingredient_classifications",
        ["food_type"],
        unique=False,
    )

    op.create_index(
        "ix_ingredient_classifications_confidence",
        "ingredient_classifications",
        ["confidence"],
        unique=False,
    )

    op.create_index(
        "ix_ingredient_classifications_reviewed",
        "ingredient_classifications",
        ["reviewed"],
        unique=False,
    )


# ---------------------------------------------------------------------------
# Downgrade
# ---------------------------------------------------------------------------


def downgrade() -> None:
    op.drop_index(
        "ix_ingredient_classifications_reviewed",
        table_name="ingredient_classifications",
    )

    op.drop_index(
        "ix_ingredient_classifications_confidence",
        table_name="ingredient_classifications",
    )

    op.drop_index(
        "ix_ingredient_classifications_food_type",
        table_name="ingredient_classifications",
    )

    op.drop_index(
        "ix_ingredient_classifications_ingredient_id",
        table_name="ingredient_classifications",
    )

    op.drop_table("ingredient_classifications")

    op.drop_index(
        "ix_ingredient_rules_priority",
        table_name="ingredient_rules",
    )

    op.drop_index(
        "ix_ingredient_rules_food_type",
        table_name="ingredient_rules",
    )

    op.drop_index(
        "ix_ingredient_rules_pattern",
        table_name="ingredient_rules",
    )

    op.drop_index(
        "ix_ingredient_rules_family_id",
        table_name="ingredient_rules",
    )

    op.drop_table("ingredient_rules")

    op.drop_index(
        "ix_ingredient_families_food_type",
        table_name="ingredient_families",
    )

    op.drop_index(
        "ix_ingredient_families_name",
        table_name="ingredient_families",
    )

    op.drop_table("ingredient_families")