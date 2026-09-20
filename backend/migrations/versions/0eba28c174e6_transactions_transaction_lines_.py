"""transactions, transaction_lines, transaction_history

Mirrors packages/ledgerly_data/lib/src/db/schema.drift's transactions/transaction_lines/
transaction_history tables line for line — same generated-column formulas (Postgres and SQLite
both do truncating integer division on two integers, so "integer half-up" behaves identically on
both sides), same CHECK constraints translated to Postgres syntax (GLOB -> a regex CHECK).

transaction_lines has no sync cols of its own (no created_at/updated_at/deleted_at): lines travel
inside their bill on push/pull — a bill's lines are always replaced wholesale, never diffed line
by line, so there is nothing for a line's own timestamp to mean.

transaction_history is append-only, one row per losing write a sync push discovers, keyed by a
deterministic id (uuid5 of transaction_id + loser's updated_at + loser's device) so that if two
different pushes both discover the same losing version, they collide into the same history row
instead of duplicating it.

Revision ID: 0eba28c174e6
Revises: 9ee8d2133de4
Create Date: 2026-09-20 07:10:00.000000

"""

from collections.abc import Sequence

from alembic import op

revision: str = "0eba28c174e6"
down_revision: str | Sequence[str] | None = "9ee8d2133de4"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE transactions (
            id uuid NOT NULL,
            firm_id uuid NOT NULL REFERENCES firms (id),
            customer_id uuid,
            device_short_code text NOT NULL,
            display_seq bigint NOT NULL CHECK (display_seq > 0),
            type text NOT NULL CHECK (
                type IN ('sale', 'purchase', 'cash_in', 'cash_out', 'opening_balance', 'adjustment')
            ),
            entry_date text NOT NULL CHECK (entry_date ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
            description text,
            version bigint NOT NULL DEFAULT 1 CHECK (version >= 1),
            calculated_total bigint NOT NULL,
            overridden_total bigint,
            overridden_total_basis bigint,
            final_amount bigint NOT NULL,
            signed_amount bigint GENERATED ALWAYS AS (
                CASE type
                    WHEN 'sale' THEN final_amount
                    WHEN 'cash_out' THEN final_amount
                    WHEN 'opening_balance' THEN final_amount
                    WHEN 'adjustment' THEN final_amount
                    WHEN 'purchase' THEN -final_amount
                    WHEN 'cash_in' THEN -final_amount
                END
            ) STORED,
            created_by_user_id uuid NOT NULL REFERENCES users (id),
            updated_by_user_id uuid NOT NULL REFERENCES users (id),
            created_at bigint NOT NULL,
            updated_at bigint NOT NULL,
            updated_by_device_id uuid NOT NULL,
            deleted_at bigint,
            PRIMARY KEY (id),
            CONSTRAINT transactions_firm_id_id_unique UNIQUE (firm_id, id),
            CONSTRAINT transactions_firm_id_customer_id_fkey
                FOREIGN KEY (firm_id, customer_id) REFERENCES customers (firm_id, id),
            CONSTRAINT transactions_final_amount_check CHECK (
                (type = 'adjustment' AND final_amount <> 0)
                OR (type <> 'adjustment' AND final_amount > 0)
            )
        )
        """
    )
    op.execute(
        "CREATE INDEX idx_txn_balance ON transactions (firm_id, customer_id, signed_amount) "
        "WHERE deleted_at IS NULL"
    )
    op.execute(
        "CREATE INDEX idx_txn_ledger "
        "ON transactions (firm_id, customer_id, entry_date, created_at, id) "
        "WHERE deleted_at IS NULL"
    )
    op.execute(
        "CREATE INDEX idx_txn_walkin ON transactions (firm_id, entry_date) "
        "WHERE customer_id IS NULL"
    )

    op.execute(
        """
        CREATE TABLE transaction_lines (
            id uuid NOT NULL,
            firm_id uuid NOT NULL,
            transaction_id uuid NOT NULL,
            line_no bigint NOT NULL CHECK (line_no >= 0),
            item_id uuid NOT NULL,
            uom text NOT NULL DEFAULT 'kg' CHECK (uom IN ('kg', 'unit')),
            sale_mode text NOT NULL CHECK (sale_mode IN ('by_bags', 'by_weight', 'by_count')),
            bag_count bigint CHECK (bag_count IS NULL OR bag_count > 0),
            bag_weight_g bigint CHECK (bag_weight_g IS NULL OR bag_weight_g > 0),
            total_weight_g bigint CHECK (total_weight_g IS NULL OR total_weight_g > 0),
            quantity bigint CHECK (quantity IS NULL OR quantity > 0),
            rate_paisa bigint NOT NULL CHECK (rate_paisa > 0),
            rate_base_weight_g bigint CHECK (rate_base_weight_g IS NULL OR rate_base_weight_g > 0),
            overridden_total bigint,
            -- final_amount duplicates this CASE rather than referencing
            -- calculated_total: unlike SQLite, Postgres refuses to let one
            -- generated column reference another ("cannot use generated
            -- column ... in column generation expression").
            calculated_total bigint GENERATED ALWAYS AS (
                CASE uom
                    WHEN 'kg' THEN
                        (rate_paisa * total_weight_g + rate_base_weight_g / 2) / rate_base_weight_g
                    WHEN 'unit' THEN rate_paisa * quantity
                END
            ) STORED,
            final_amount bigint GENERATED ALWAYS AS (
                COALESCE(
                    overridden_total,
                    CASE uom
                        WHEN 'kg' THEN
                            (rate_paisa * total_weight_g + rate_base_weight_g / 2)
                                / rate_base_weight_g
                        WHEN 'unit' THEN rate_paisa * quantity
                    END
                )
            ) STORED,
            PRIMARY KEY (id),
            CONSTRAINT transaction_lines_firm_id_transaction_id_fkey
                FOREIGN KEY (firm_id, transaction_id) REFERENCES transactions (firm_id, id)
                ON DELETE CASCADE,
            CONSTRAINT transaction_lines_firm_id_item_id_fkey
                FOREIGN KEY (firm_id, item_id) REFERENCES items (firm_id, id),
            CONSTRAINT transaction_lines_bags_check
                CHECK (
                    (sale_mode = 'by_bags') = (bag_count IS NOT NULL AND bag_weight_g IS NOT NULL)
                ),
            CONSTRAINT transaction_lines_kg_check
                CHECK (
                    (uom = 'kg') = (total_weight_g IS NOT NULL AND rate_base_weight_g IS NOT NULL)
                ),
            CONSTRAINT transaction_lines_unit_check CHECK ((uom = 'unit') = (quantity IS NOT NULL))
        )
        """
    )
    op.execute(
        "CREATE UNIQUE INDEX idx_lines_no ON transaction_lines (firm_id, transaction_id, line_no)"
    )
    op.execute("CREATE INDEX idx_lines_item ON transaction_lines (firm_id, item_id)")

    op.execute(
        """
        CREATE TABLE transaction_history (
            id uuid NOT NULL,
            firm_id uuid NOT NULL,
            transaction_id uuid NOT NULL,
            version bigint NOT NULL,
            snapshot jsonb NOT NULL,
            reason text NOT NULL CHECK (reason IN ('edit', 'delete', 'sync_overwrite', 'restore')),
            changed_at bigint NOT NULL,
            changed_by_user_id uuid NOT NULL,
            changed_by_device_id uuid NOT NULL,
            PRIMARY KEY (id),
            CONSTRAINT transaction_history_firm_id_transaction_id_fkey
                FOREIGN KEY (firm_id, transaction_id) REFERENCES transactions (firm_id, id)
                ON DELETE CASCADE
        )
        """
    )
    op.execute(
        "CREATE INDEX idx_history_txn ON transaction_history (firm_id, transaction_id, changed_at)"
    )


def downgrade() -> None:
    op.execute("DROP TABLE transaction_history")
    op.execute("DROP TABLE transaction_lines")
    op.execute("DROP TABLE transactions")
