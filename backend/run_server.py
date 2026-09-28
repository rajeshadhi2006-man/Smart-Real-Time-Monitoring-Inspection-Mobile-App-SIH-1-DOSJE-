import uvicorn
import os
import sys

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"Starting MoSJE ArcFace FastAPI Server on {host}:{port}...")
    uvicorn.run("app.main:app", host=host, port=port, reload=False, log_level="info")
