from uuid import UUID

from app.models.community_comment import CommunityComment
from app.models.community_like import CommunityLike
from app.models.community_post import CommunityPost
from app.models.user import User
from app.repositories.community_repository import CommunityRepository
from app.repositories.recipe_repository import RecipeRepository


class CommunityService:
    def __init__(
        self,
        community_repository: CommunityRepository,
        recipe_repository: RecipeRepository,
    ):
        self.community_repository = community_repository
        self.recipe_repository = recipe_repository

    # =========================================================
    # POSTS
    # =========================================================

    def create_post(
        self,
        content: str,
        recipe_id: UUID | None,
        current_user: User,
    ) -> dict:
        content = content.strip()

        if not content:
            raise ValueError("Post content cannot be empty.")

        if recipe_id is not None:
            recipe = self.recipe_repository.get_by_id(recipe_id)

            if recipe is None:
                raise ValueError("Recipe not found.")

        post = CommunityPost(
            content=content,
            author_id=current_user.id,
            recipe_id=recipe_id,
        )

        post = self.community_repository.create_post(post)

        return self._serialize_post(
            post,
            current_user.id,
        )

    def get_posts(
        self,
        current_user: User,
        limit: int = 20,
        offset: int = 0,
    ) -> list[dict]:
        if limit < 1 or limit > 50:
            raise ValueError("Limit must be between 1 and 50.")

        if offset < 0:
            raise ValueError("Offset cannot be negative.")

        posts = self.community_repository.get_posts(
            limit=limit,
            offset=offset,
        )

        return [
            self._serialize_post(
                post,
                current_user.id,
            )
            for post in posts
        ]

    def get_post(
        self,
        post_id: UUID,
        current_user: User,
    ) -> dict:
        post = self.community_repository.get_post_by_id(
            post_id,
        )

        if post is None:
            raise ValueError("Community post not found.")

        return self._serialize_post(
            post,
            current_user.id,
            include_comments=True,
        )

    def delete_post(
        self,
        post_id: UUID,
        current_user: User,
    ) -> None:
        post = self.community_repository.get_post_by_id(
            post_id,
        )

        if post is None:
            raise ValueError("Community post not found.")

        if post.author_id != current_user.id:
            raise PermissionError(
                "You can only delete your own posts."
            )

        self.community_repository.delete_post(post)

    # =========================================================
    # LIKES
    # =========================================================

    def like_post(
        self,
        post_id: UUID,
        current_user: User,
    ) -> dict:
        post = self.community_repository.get_post_by_id(
            post_id,
        )

        if post is None:
            raise ValueError("Community post not found.")

        existing_like = self.community_repository.get_like(
            post_id,
            current_user.id,
        )

        if existing_like is None:
            like = CommunityLike(
                post_id=post_id,
                user_id=current_user.id,
            )

            self.community_repository.create_like(like)

        return {
            "post_id": str(post_id),
            "is_liked": True,
            "like_count": self.community_repository.get_like_count(
                post_id
            ),
        }

    def unlike_post(
        self,
        post_id: UUID,
        current_user: User,
    ) -> dict:
        post = self.community_repository.get_post_by_id(
            post_id,
        )

        if post is None:
            raise ValueError("Community post not found.")

        existing_like = self.community_repository.get_like(
            post_id,
            current_user.id,
        )

        if existing_like is not None:
            self.community_repository.delete_like(
                existing_like,
            )

        return {
            "post_id": str(post_id),
            "is_liked": False,
            "like_count": self.community_repository.get_like_count(
                post_id
            ),
        }

    # =========================================================
    # COMMENTS
    # =========================================================

    def create_comment(
        self,
        post_id: UUID,
        content: str,
        current_user: User,
    ) -> CommunityComment:
        content = content.strip()

        if not content:
            raise ValueError(
                "Comment content cannot be empty."
            )

        post = self.community_repository.get_post_by_id(
            post_id,
        )

        if post is None:
            raise ValueError("Community post not found.")

        comment = CommunityComment(
            content=content,
            post_id=post_id,
            author_id=current_user.id,
        )

        return self.community_repository.create_comment(
            comment,
        )

    def get_comments(
        self,
        post_id: UUID,
    ) -> list[CommunityComment]:
        post = self.community_repository.get_post_by_id(
            post_id,
        )

        if post is None:
            raise ValueError("Community post not found.")

        return self.community_repository.get_comments(
            post_id,
        )

    def delete_comment(
        self,
        comment_id: UUID,
        current_user: User,
    ) -> None:
        comment = self.community_repository.get_comment_by_id(
            comment_id,
        )

        if comment is None:
            raise ValueError("Community comment not found.")

        if comment.author_id != current_user.id:
            raise PermissionError(
                "You can only delete your own comments."
            )

        self.community_repository.delete_comment(
            comment,
        )

    # =========================================================
    # SERIALIZATION
    # =========================================================

    def _serialize_post(
        self,
        post: CommunityPost,
        current_user_id: UUID,
        include_comments: bool = False,
    ) -> dict:
        comments = [
            self._serialize_comment(comment)
            for comment in post.comments
        ]

        result = {
            "id": post.id,
            "content": post.content,
            "author": {
                "id": post.author.id,
                "username": post.author.username,
            },
            "recipe": (
                {
                    "id": post.recipe.id,
                    "title": post.recipe.title,
                    "image_url": post.recipe.image_url,
                }
                if post.recipe is not None
                else None
            ),
            "like_count": len(post.likes),
            "comment_count": len(post.comments),
            "is_liked": any(
                like.user_id == current_user_id
                for like in post.likes
            ),
            "created_at": post.created_at,
            "updated_at": post.updated_at,
        }

        if include_comments:
            result["comments"] = comments

        return result

    @staticmethod
    def _serialize_comment(
        comment: CommunityComment,
    ) -> dict:
        return {
            "id": comment.id,
            "content": comment.content,
            "author": {
                "id": comment.author.id,
                "username": comment.author.username,
            },
            "created_at": comment.created_at,
        }