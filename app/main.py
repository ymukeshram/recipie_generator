from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1.endpoints import recipes

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="RasoiAI - Backend API for AI-Powered Indian Cooking Assistant",
)

# CORS middleware for Flutter web preview and mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Routers
app.include_router(
    recipes.router,
    prefix=f"{settings.API_V1_STR}/recipes",
    tags=["recipes"],
)

@app.get("/")
def root():
    return {
        "app": "RasoiAI API",
        "version": settings.VERSION,
        "status": "online",
        "docs": "/docs",
    }

@app.get("/health")
@app.get(f"{settings.API_V1_STR}/health")
def health_check():
    return {
        "status": "healthy",
        "gemini_configured": bool(settings.GEMINI_API_KEY),
        "supabase_configured": bool(settings.SUPABASE_URL),
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
