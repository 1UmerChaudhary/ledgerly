import time

from httpx import AsyncClient


async def test_time_returns_the_servers_current_clock_in_milliseconds(
    client: AsyncClient,
) -> None:
    before = int(time.time() * 1000)

    response = await client.get("/sync/time")

    after = int(time.time() * 1000)
    assert response.status_code == 200
    server_time = response.json()["server_time"]
    # loose bound: proves it's a real clock reading, not a fixed placeholder
    assert before <= server_time <= after
