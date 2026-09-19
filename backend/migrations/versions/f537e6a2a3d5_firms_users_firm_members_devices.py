"""firms, users, firm_members, devices

Mirrors packages/ledgerly_data/lib/src/db/schema.drift on the device, translated to Postgres:
uuid instead of a checked text column, bigint instead of SQLite's INTEGER for money-scale numbers.
Timestamps (created_at, updated_at, deleted_at) are HLC milliseconds, not Postgres timestamps —
same rule as the device schema, so a stamp compares the same way on both sides.

Row Level Security is not part of this migration. RLS needs a real non-superuser database role to
mean anything (the table owner bypasses it, so testing against one would prove nothing); that role
comes with the auth work, not the schema.

Revision ID: f537e6a2a3d5
Revises:
Create Date: 2026-09-19 19:46:50.078560

"""

from collections.abc import Sequence

from alembic import op

revision: str = "f537e6a2a3d5"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")
    op.execute(
        """
        CREATE TABLE firms (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            name text NOT NULL,
            contact_number text NOT NULL,
            address text,
            logo_blob bytea,
            number_grouping text NOT NULL CHECK (number_grouping IN ('pakistani', 'western')),
            show_paisa boolean NOT NULL DEFAULT false,
            default_country_code text NOT NULL DEFAULT '92',
            created_at bigint NOT NULL,
            updated_at bigint NOT NULL,
            updated_by_device_id uuid NOT NULL,
            deleted_at bigint,
            next_seq bigint NOT NULL DEFAULT 0,
            min_valid_cursor bigint NOT NULL DEFAULT 0
        )
        """
    )
    op.execute(
        """
        -- Global identity: one row per person, shared across every firm they belong to.
        -- No firm_id here on purpose (see docs/design-spec.md Section 2) — a user is visible
        -- only through firm_members, which is where RLS will scope it.
        CREATE TABLE users (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            name text NOT NULL,
            email text NOT NULL,
            password_hash text,
            google_sub text,
            created_at bigint NOT NULL,
            updated_at bigint NOT NULL,
            updated_by_device_id uuid NOT NULL,
            deleted_at bigint,
            CONSTRAINT users_email_unique UNIQUE (email),
            CONSTRAINT users_google_sub_unique UNIQUE (google_sub)
        )
        """
    )
    op.execute(
        """
        CREATE TABLE firm_members (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            firm_id uuid NOT NULL REFERENCES firms (id),
            user_id uuid NOT NULL REFERENCES users (id),
            role text NOT NULL CHECK (role IN ('owner', 'manager', 'clerk')),
            created_at bigint NOT NULL,
            updated_at bigint NOT NULL,
            updated_by_device_id uuid NOT NULL,
            deleted_at bigint,
            CONSTRAINT firm_members_firm_id_id_unique UNIQUE (firm_id, id)
        )
        """
    )
    op.execute(
        """
        CREATE UNIQUE INDEX firm_members_one_active_membership
            ON firm_members (firm_id, user_id) WHERE deleted_at IS NULL
        """
    )
    op.execute(
        """
        CREATE TABLE devices (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            firm_id uuid NOT NULL REFERENCES firms (id),
            name text NOT NULL,
            platform text NOT NULL,
            short_code text NOT NULL,
            created_at bigint NOT NULL,
            updated_at bigint NOT NULL,
            updated_by_device_id uuid NOT NULL,
            deleted_at bigint,
            CONSTRAINT devices_firm_id_id_unique UNIQUE (firm_id, id),
            CONSTRAINT devices_firm_id_short_code_unique UNIQUE (firm_id, short_code)
        )
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE devices")
    op.execute("DROP TABLE firm_members")
    op.execute("DROP TABLE users")
    op.execute("DROP TABLE firms")
