from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="{{PROJECT_NAME}}", version="1.0.0")

class HealthResponse(BaseModel):
    status: str
    service: str

@app.get("/", response_model=HealthResponse)
async def root():
    return {"status": "ok", "service": "{{PROJECT_NAME}}"}

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "query": q}
