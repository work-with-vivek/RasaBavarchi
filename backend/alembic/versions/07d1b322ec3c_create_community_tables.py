"""create community tables

Revision ID: 07d1b322ec3c
Revises: ad0875ea9eef
Create Date: 2026-09-13 14:04:59.399943

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "07d1b322ec3c"
down_revision: Union[str, Sequence[str], None] = "ad0875ea9eef"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create Community tables."""

    # ---------------------------------------------------------
    # COMMUNITY POSTS
    # ---------------------------------------------------------

    op.create_table(
        "community_posts",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("author_id", sa.UUID(), nullable=False),
        sa.Column("recipe_id", sa.UUID(), nullable=True),
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
            ["author_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["recipe_id"],
            ["recipes.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        "ix_community_posts_author_id",
        "community_posts",
        ["author_id"],
        unique=False,
    )

    op.create_index(
        "ix_community_posts_recipe_id",
        "community_posts",
        ["recipe_id"],
        unique=False,
    )

    # ---------------------------------------------------------
    # COMMUNITY COMMENTS
    # ---------------------------------------------------------

    op.create_table(
        "community_comments",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("post_id", sa.UUID(), nullable=False),
        sa.Column("author_id", sa.UUID(), nullable=False),
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
            ["author_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["post_id"],
            ["community_posts.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        "ix_community_comments_author_id",
        "community_comments",
        ["author_id"],
        unique=False,
    )

    op.create_index(
        "ix_community_comments_post_id",
        "community_comments",
        ["post_id"],
        unique=False,
    )

    # ---------------------------------------------------------
    # COMMUNITY LIKES
    # ---------------------------------------------------------

    op.create_table(
        "community_likes",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("post_id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
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
            ["post_id"],
            ["community_posts.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "post_id",
            "user_id",
            name="uq_community_like_post_user",
        ),
    )

    op.create_index(
        "ix_community_likes_post_id",
        "community_likes",
        ["post_id"],
        unique=False,
    )

    op.create_index(
        "ix_community_likes_user_id",
        "community_likes",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    """Drop Community tables."""

    op.drop_index(
        "ix_community_likes_user_id",
        table_name="community_likes",
    )

    op.drop_index(
        "ix_community_likes_post_id",
        table_name="community_likes",
    )

    op.drop_table("community_likes")

    op.drop_index(
        "ix_community_comments_post_id",
        table_name="community_comments",
    )

    op.drop_index(
        "ix_community_comments_author_id",
        table_name="community_comments",
    )

    op.drop_table("community_comments")

    op.drop_index(
        "ix_community_posts_recipe_id",
        table_name="community_posts",
    )

    op.drop_index(
        "ix_community_posts_author_id",
        table_name="community_posts",
    )

    op.drop_table("community_posts")