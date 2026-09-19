import uuid

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession


def _new_firm_row() -> dict:
    return {
        "id": str(uuid.uuid4()),
        "name": "Al-Madina Oil Mills",
        "contact_number": "0300-1234567",
        "number_grouping": "pakistani",
        "created_at": 1000,
        "updated_at": 1000,
        "updated_by_device_id": str(uuid.uuid4()),
    }


async def _insert_firm(db_session: AsyncSession, firm: dict) -> None:
    await db_session.execute(
        text(
            """
            INSERT INTO firms
                (id, name, contact_number, number_grouping, created_at, updated_at,
                 updated_by_device_id)
            VALUES
                (:id, :name, :contact_number, :number_grouping, :created_at, :updated_at,
                 :updated_by_device_id)
            """
        ),
        firm,
    )


async def test_creates_a_firm_and_reads_it_back(db_session: AsyncSession) -> None:
    firm = _new_firm_row()
    await _insert_firm(db_session, firm)

    row = (
        await db_session.execute(text("SELECT name, show_paisa FROM firms WHERE id = :id"), firm)
    ).one()

    assert row.name == "Al-Madina Oil Mills"
    assert row.show_paisa is False  # the column default


async def test_number_grouping_check_rejects_an_unknown_value(db_session: AsyncSession) -> None:
    firm = _new_firm_row()
    firm["number_grouping"] = "metric"  # not one of pakistani/western

    with pytest.raises(IntegrityError, match="firms_number_grouping_check"):
        await _insert_firm(db_session, firm)


async def test_a_user_can_only_have_one_active_membership_in_a_firm(
    db_session: AsyncSession,
) -> None:
    firm = _new_firm_row()
    await _insert_firm(db_session, firm)
    user_id = str(uuid.uuid4())
    device_id = str(uuid.uuid4())
    await db_session.execute(
        text(
            "INSERT INTO users (id, name, email, created_at, updated_at, updated_by_device_id) "
            "VALUES (:id, 'Rashid', 'rashid@example.com', 1000, 1000, :device_id)"
        ),
        {"id": user_id, "device_id": device_id},
    )

    async def add_membership(role: str) -> None:
        await db_session.execute(
            text(
                "INSERT INTO firm_members "
                "(id, firm_id, user_id, role, created_at, updated_at, updated_by_device_id) "
                "VALUES (:id, :firm_id, :user_id, :role, 1000, 1000, :device_id)"
            ),
            {
                "id": str(uuid.uuid4()),
                "firm_id": firm["id"],
                "user_id": user_id,
                "role": role,
                "device_id": device_id,
            },
        )

    await add_membership("owner")

    with pytest.raises(IntegrityError, match="firm_members_one_active_membership"):
        await add_membership("clerk")
