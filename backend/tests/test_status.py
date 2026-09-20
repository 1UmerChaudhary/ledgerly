from fastapi.testclient import TestClient

from app.main import app


def test_status_reports_ok():
    response = TestClient(app).get("/status")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
