"""customers

Mirrors packages/ledgerly_data/lib/src/db/schema.drift's `customers` table, with one deliberate
difference: the device enforces phone uniqueness as a hard UNIQUE index (blocking local creation
before it ever reaches the server), but the server must NOT — its whole job on a phone collision
is to accept both rows and flag needs_review (or auto-merge when the name matches too), per
docs/design-spec.md Section 4 step 3 ("Cross-device: server detects phone collision on push,
keeps both, sets needs_review on both"). A hard UNIQUE constraint here would make that impossible;
a plain index still makes the collision lookup on push fast.

Revision ID: 9ee8d2133de4
Revises: c4e5188f4162
Create Date: 2026-09-20 06:48:25.506218

"""

from collections.abc import Sequence

from alembic import op

revision: str = "9ee8d2133de4"
down_revision: str | Sequence[str] | None = "c4e5188f4162"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE customers (
            id uuid NOT NULL,
            firm_id uuid NOT NULL REFERENCES firms (id),
            name text NOT NULL,
            name_normalized text NOT NULL,
            phone text,
            phone_normalized text,
            notes text,
            created_by_user_id uuid NOT NULL REFERENCES users (id),
            merged_into_id uuid REFERENCES customers (id),
            needs_review boolean NOT NULL DEFAULT false,
            created_at bigint NOT NULL,
            updated_at bigint NOT NULL,
            updated_by_device_id uuid NOT NULL,
            deleted_at bigint,
            PRIMARY KEY (id),
            CONSTRAINT customers_firm_id_id_unique UNIQUE (firm_id, id)
        )
        """
    )
    op.execute(
        "CREATE INDEX customers_firm_id_phone_normalized "
        "ON customers (firm_id, phone_normalized) "
        "WHERE deleted_at IS NULL AND merged_into_id IS NULL"
    )
    op.execute(
        "CREATE INDEX customers_firm_id_name_normalized ON customers (firm_id, name_normalized)"
    )


def downgrade() -> None:
    op.execute("DROP TABLE customers")
