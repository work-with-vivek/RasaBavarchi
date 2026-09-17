from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.models.community_comment import CommunityComment
from app.models.community_like import CommunityLike
from app.models.community_post import CommunityPost


class CommunityRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    # =========================================================
    # POSTS
    # =========================================================

    def create_post(
        self,
        post: CommunityPost,
    ) -> CommunityPost:

        self.db.add(post)
        self.db.commit()
        self.db.refresh(post)

        return self.get_post_by_id(post.id)

    def get_post_by_id(
        self,
        post_id: UUID,
    ) -> CommunityPost | None:

        statement = (
            select(CommunityPost)
            .options(
                selectinload(CommunityPost.author),
                selectinload(CommunityPost.recipe),
                selectinload(CommunityPost.likes),
                selectinload(CommunityPost.comments).selectinload(
                    CommunityComment.author
                ),
            )
            .where(
                CommunityPost.id == post_id,
            )
        )

        return self.db.scalar(statement)

    def get_posts(
        self,
        limit: int = 20,
        offset: int = 0,
    ) -> list[CommunityPost]:

        statement = (
            select(CommunityPost)
            .options(
                selectinload(CommunityPost.author),
                selectinload(CommunityPost.recipe),
                selectinload(CommunityPost.likes),
                selectinload(CommunityPost.comments),
            )
            .order_by(
                CommunityPost.created_at.desc(),
            )
            .offset(offset)
            .limit(limit)
        )

        return self.db.scalars(statement).unique().all()

    def delete_post(
        self,
        post: CommunityPost,
    ) -> None:

        self.db.delete(post)
        self.db.commit()

    # =========================================================
    # LIKES
    # =========================================================

    def get_like(
        self,
        post_id: UUID,
        user_id: UUID,
    ) -> CommunityLike | None:

        statement = (
            select(CommunityLike)
            .where(
                CommunityLike.post_id == post_id,
                CommunityLike.user_id == user_id,
            )
        )

        return self.db.scalar(statement)

    def create_like(
        self,
        like: CommunityLike,
    ) -> CommunityLike:

        self.db.add(like)
        self.db.commit()
        self.db.refresh(like)

        return like

    def delete_like(
        self,
        like: CommunityLike,
    ) -> None:

        self.db.delete(like)
        self.db.commit()

    def get_like_count(
        self,
        post_id: UUID,
    ) -> int:

        statement = (
            select(func.count())
            .select_from(CommunityLike)
            .where(
                CommunityLike.post_id == post_id,
            )
        )

        return self.db.scalar(statement) or 0

    # =========================================================
    # COMMENTS
    # =========================================================

    def create_comment(
        self,
        comment: CommunityComment,
    ) -> CommunityComment:

        self.db.add(comment)
        self.db.commit()
        self.db.refresh(comment)

        return self.get_comment_by_id(comment.id)

    def get_comment_by_id(
        self,
        comment_id: UUID,
    ) -> CommunityComment | None:

        statement = (
            select(CommunityComment)
            .options(
                selectinload(CommunityComment.author),
            )
            .where(
                CommunityComment.id == comment_id,
            )
        )

        return self.db.scalar(statement)

    def get_comments(
        self,
        post_id: UUID,
    ) -> list[CommunityComment]:

        statement = (
            select(CommunityComment)
            .options(
                selectinload(CommunityComment.author),
            )
            .where(
                CommunityComment.post_id == post_id,
            )
            .order_by(
                CommunityComment.created_at.asc(),
            )
        )

        return self.db.scalars(statement).all()

    def delete_comment(
        self,
        comment: CommunityComment,
    ) -> None:

        self.db.delete(comment)
        self.db.commit()

    def get_comment_count(
        self,
        post_id: UUID,
    ) -> int:

        statement = (
            select(func.count())
            .select_from(CommunityComment)
            .where(
                CommunityComment.post_id == post_id,
            )
        )

        return self.db.scalar(statement) or 0