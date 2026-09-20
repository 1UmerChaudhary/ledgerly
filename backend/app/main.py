from fastapi import FastAPI

from app.routers import auth, sync

app = FastAPI(title="Ledgerly Sync API")
app.include_router(auth.router)
app.include_router(sync.router)


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}
