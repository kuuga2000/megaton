from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"service": "valkey", "status": "running"}

@app.get("/keys")
def keys():
    return {"key": "VALKEY-SAMPLE-1234", "valid": True}
