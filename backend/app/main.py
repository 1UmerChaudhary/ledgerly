from fastapi import FastAPI

from app.routers import auth

app = FastAPI(title="Ledgerly Sync API")
app.include_router(auth.router)


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}
