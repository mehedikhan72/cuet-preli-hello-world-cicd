from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/hello-world")
async def hello_world():
    message = "Hello World"
    print(f"Endpoint hit: {message}")
    return {"message": message}

@app.get("/health")
async def health():
    return {"status": "healthy"}