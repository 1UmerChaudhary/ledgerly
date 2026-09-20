from fastapi import FastAPI

from app.routers import auth, sync

app = FastAPI(title="Ledgerly Sync API")
app.include_router(auth.router)
app.include_router(sync.router)


# Named /status, not /healthz or /health -- Cloud Run's edge (GFE) reserves
# any path prefixed "health" for its own internal probing and never forwards
# it to the container, returning its own 404 before the app ever sees it.
@app.get("/status")
def status() -> dict[str, str]:
    return {"status": "ok"}
