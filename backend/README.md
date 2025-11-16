# Backend (Flask)

Structure
- app/
  - __init__.py — Flask app factory, config, DB init
  - models.py — SQLAlchemy models (Users, Transactions)
  - routes.py — REST endpoints (/api)
  - fraud_detector.py — ML pipeline and heuristics
- requirements.txt — dependencies
- run.py — entry point

Run locally
- python -m venv .venv
- .venv/Scripts/activate (Windows) or source .venv/bin/activate (Unix)
- pip install -r requirements.txt
- cp .env.example .env and set values
- python run.py

Environment vars
- SECRET_KEY
- SQLALCHEMY_DATABASE_URI
- OPENROUTER_API_KEY, OPENROUTER_BASE_URL, OPENROUTER_HTTP_REFERER, OPENROUTER_MODEL
- API_PREFIX (default /api)
- HOST, PORT

API contract
See API.md and Architecture.md. Key endpoints:
- POST /api/check-fraud
- GET /api/users/<user_id>/transactions

Notes
- Use SQLite in dev; swap to PostgreSQL in production.
- Add rate limiting and CORS as needed.
