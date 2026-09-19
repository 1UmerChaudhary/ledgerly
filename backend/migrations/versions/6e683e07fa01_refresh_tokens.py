"""refresh tokens

One row per (user, device): login/register/refresh all replace it outright, so a device only
ever has the one refresh token that's actually valid — the previous one stops working the moment
a new one is issued, which is what makes rotation mean anything.

Revision ID: 6e683e07fa01
Revises: f537e6a2a3d5
Create Date: 2026-09-19 19:53:27.109730

"""

from collections.abc import Sequence

from alembic import op

revision: str = "6e683e07fa01"
down_revision: str | Sequence[str] | None = "f537e6a2a3d5"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE refresh_tokens (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid NOT NULL REFERENCES users (id),
            device_id uuid NOT NULL,
            token_hash text NOT NULL,
            created_at bigint NOT NULL,
            expires_at bigint NOT NULL,
            CONSTRAINT refresh_tokens_token_hash_unique UNIQUE (token_hash),
            CONSTRAINT refresh_tokens_user_id_device_id_unique UNIQUE (user_id, device_id)
        )
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE refresh_tokens")
