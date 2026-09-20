import uuid

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_firm_user_customer_item(db: AsyncSession) -> dict:
    firm_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    device_id = str(uuid.uuid4())
    customer_id = str(uuid.uuid4())
    item_id = str(uuid.uuid4())
    await db.execute(
        text(
            "INSERT INTO firms (id, name, contact_number, number_grouping, created_at, "
            "updated_at, updated_by_device_id) "
            "VALUES (:id, 'Mill', '0300', 'pakistani', 1000, 1000, :device_id)"
        ),
        {"id": firm_id, "device_id": device_id},
    )
    await db.execute(
        text(
            "INSERT INTO users (id, name, email, created_at, updated_at, updated_by_device_id) "
            "VALUES (:id, 'Owner', :email, 1000, 1000, :device_id)"
        ),
        {"id": user_id, "email": f"{user_id}@example.com", "device_id": device_id},
    )
    await db.execute(
        text(
            "INSERT INTO customers (id, firm_id, name, name_normalized, created_by_user_id, "
            "created_at, updated_at, updated_by_device_id) "
            "VALUES (:id, :firm_id, 'Rashid', 'rashid', :user_id, 1000, 1000, :device_id)"
        ),
        {"id": customer_id, "firm_id": firm_id, "user_id": user_id, "device_id": device_id},
    )
    await db.execute(
        text(
            "INSERT INTO items (id, firm_id, name, name_normalized, created_by_user_id, "
            "created_at, updated_at, updated_by_device_id) "
            "VALUES (:id, :firm_id, 'Oil', 'oil', :user_id, 1000, 1000, :device_id)"
        ),
        {"id": item_id, "firm_id": firm_id, "user_id": user_id, "device_id": device_id},
    )
    return {
        "firm_id": firm_id,
        "user_id": user_id,
        "device_id": device_id,
        "customer_id": customer_id,
        "item_id": item_id,
    }


async def _insert_transaction(db: AsyncSession, ctx: dict, *, type_: str, final_amount: int) -> str:
    txn_id = str(uuid.uuid4())
    await db.execute(
        text(
            """
            INSERT INTO transactions
                (id, firm_id, customer_id, device_short_code, display_seq, type, entry_date,
                 version, calculated_total, final_amount, created_by_user_id,
                 updated_by_user_id, created_at, updated_at, updated_by_device_id)
            VALUES
                (:id, :firm_id, :customer_id, 'A3F9', 1, :type, '2026-09-20', 1,
                 :final_amount, :final_amount, :user_id, :user_id, 1000, 1000, :device_id)
            """
        ),
        {
            "id": txn_id,
            "firm_id": ctx["firm_id"],
            "customer_id": ctx["customer_id"],
            "type": type_,
            "final_amount": final_amount,
            "user_id": ctx["user_id"],
            "device_id": ctx["device_id"],
        },
    )
    return txn_id


async def test_signed_amount_is_positive_for_a_sale(db_session: AsyncSession) -> None:
    ctx = await _seed_firm_user_customer_item(db_session)
    txn_id = await _insert_transaction(db_session, ctx, type_="sale", final_amount=50000)

    signed = (
        await db_session.execute(
            text("SELECT signed_amount FROM transactions WHERE id = :id"), {"id": txn_id}
        )
    ).scalar_one()

    assert signed == 50000


async def test_signed_amount_is_negative_for_a_purchase(db_session: AsyncSession) -> None:
    ctx = await _seed_firm_user_customer_item(db_session)
    txn_id = await _insert_transaction(db_session, ctx, type_="purchase", final_amount=30000)

    signed = (
        await db_session.execute(
            text("SELECT signed_amount FROM transactions WHERE id = :id"), {"id": txn_id}
        )
    ).scalar_one()

    assert signed == -30000


async def test_final_amount_check_rejects_a_zero_sale(db_session: AsyncSession) -> None:
    ctx = await _seed_firm_user_customer_item(db_session)

    with pytest.raises(IntegrityError, match="transactions_final_amount_check"):
        await _insert_transaction(db_session, ctx, type_="sale", final_amount=0)


async def test_line_calculated_total_rounds_half_up(db_session: AsyncSession) -> None:
    ctx = await _seed_firm_user_customer_item(db_session)
    txn_id = await _insert_transaction(db_session, ctx, type_="sale", final_amount=167)
    line_id = str(uuid.uuid4())

    await db_session.execute(
        text(
            """
            INSERT INTO transaction_lines
                (id, firm_id, transaction_id, line_no, item_id, uom, sale_mode,
                 total_weight_g, rate_paisa, rate_base_weight_g)
            VALUES
                (:id, :firm_id, :txn_id, 0, :item_id, 'kg', 'by_weight', 50, 333, 100)
            """
        ),
        {
            "id": line_id,
            "firm_id": ctx["firm_id"],
            "txn_id": txn_id,
            "item_id": ctx["item_id"],
        },
    )

    calculated, final = (
        await db_session.execute(
            text("SELECT calculated_total, final_amount FROM transaction_lines WHERE id = :id"),
            {"id": line_id},
        )
    ).one()

    # (333*50 + 100/2) / 100 = (16650+50)/100 = 167 -- half-up from the naive 166.5
    assert calculated == 167
    assert final == 167


async def test_line_final_amount_uses_the_override_when_set(db_session: AsyncSession) -> None:
    ctx = await _seed_firm_user_customer_item(db_session)
    txn_id = await _insert_transaction(db_session, ctx, type_="sale", final_amount=200)
    line_id = str(uuid.uuid4())

    await db_session.execute(
        text(
            """
            INSERT INTO transaction_lines
                (id, firm_id, transaction_id, line_no, item_id, uom, sale_mode,
                 total_weight_g, rate_paisa, rate_base_weight_g, overridden_total)
            VALUES
                (:id, :firm_id, :txn_id, 0, :item_id, 'kg', 'by_weight', 50, 333, 100, 200)
            """
        ),
        {
            "id": line_id,
            "firm_id": ctx["firm_id"],
            "txn_id": txn_id,
            "item_id": ctx["item_id"],
        },
    )

    calculated, final = (
        await db_session.execute(
            text("SELECT calculated_total, final_amount FROM transaction_lines WHERE id = :id"),
            {"id": line_id},
        )
    ).one()

    assert calculated == 167  # unaffected by the override
    assert final == 200
