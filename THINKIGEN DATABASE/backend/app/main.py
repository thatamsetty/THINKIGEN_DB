"""
Thinkigen ERP - Core Academic & Timetable API Service.
Implements production OpenAPI specs, ISO-8601 & IST datetime representations, and row_version concurrency control.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.timetable import router as timetable_router

app = FastAPI(
    title="Thinkigen Academic & Timetable API",
    version="1.0.0",
    description=(
        "Production API service for Thinkigen ERP academic timetables, daily scheduling, "
        "and period topic tracking (`subject_topic`). Adheres to SQL Server rowversion concurrency tokens, "
        "Organization scope isolation, and IST (+05:30) date-time conventions."
    ),
    contact={
        "name": "Thinkigen Platform Engineering",
        "email": "engineering@thinkigen.com",
    },
)

# Enable CORS for local and staging frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(timetable_router)


@app.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy",
        "service": "thinkigen-timetable-service",
        "version": "1.0.0",
    }
