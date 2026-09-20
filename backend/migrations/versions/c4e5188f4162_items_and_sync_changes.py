"""items and sync_changes

items mirrors packages/ledgerly_data/lib/src/db/schema.drift's `items` table. sync_changes is
server-only (docs/design-spec.md Section 4): one append-only row per push-accepted change,
keyed by (firm_id, server_seq) so a device's `since=cursor` pull is just "server_seq > cursor".

Revision ID: c4e5188f4162
Revises: 6e683e07fa01
Create Date: 2026-09-20 06:09:37.933016

"""

from collections.abc import Sequence

from alembic import op

revision: str = "c4e5188f4162"
down_revision: str | Sequence[str] | None = "6e683e07fa01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE items (
            id uuid NOT NULL,
            firm_id uuid NOT NULL REFERENCES firms (id),
            name text NOT NULL,
            name_normalized text NOT NULL,
            default_bag_weight_g bigint,
            default_rate_base_weight_g bigint,
            default_uom text NOT NULL DEFAULT 'kg' CHECK (default_uom IN ('kg', 'unit')),
            track_stock boolean NOT NULL DEFAULT false,
            created_by_user_id uuid NOT NULL REFERENCES users (id),
            created_at bigint NOT NULL,
            updated_at bigint NOT NULL,
            updated_by_device_id uuid NOT NULL,
            deleted_at bigint,
            PRIMARY KEY (id),
            CONSTRAINT items_firm_id_id_unique UNIQUE (firm_id, id)
        )
        """
    )
    op.execute("CREATE INDEX items_firm_id_name_normalized ON items (firm_id, name_normalized)")
    op.execute(
        """
        CREATE TABLE sync_changes (
            firm_id uuid NOT NULL REFERENCES firms (id),
            server_seq bigint NOT NULL,
            table_name text NOT NULL,
            row_id uuid NOT NULL,
            changed_at bigint NOT NULL,
            PRIMARY KEY (firm_id, server_seq)
        )
        """
    )
    op.execute(
        "CREATE INDEX sync_changes_firm_id_table_name_row_id "
        "ON sync_changes (firm_id, table_name, row_id)"
    )


def downgrade() -> None:
    op.execute("DROP TABLE sync_changes")
    op.execute("DROP TABLE items")
