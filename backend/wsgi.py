import os
from app import create_app

# The application entry point for a Gunicorn server
# The config name is derived from the 'FLASK_ENV' or 'ENV' environment variables.
# Render will set this to 'production' by default.
app = create_app(os.getenv("FLASK_ENV") or "production")
