import os
import logging
from logging.handlers import RotatingFileHandler
from datetime import timedelta

from flask import Flask, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

# Extensions
# They are instantiated here and initialized in create_app

db = SQLAlchemy()
migrate = Migrate()


class Config:
    # Base configuration
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-change-me")
    SQLALCHEMY_DATABASE_URI = os.getenv("SQLALCHEMY_DATABASE_URI", "sqlite:///shieldai_dev.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # API
    API_PREFIX = os.getenv("API_PREFIX", "/api")

    # CORS
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")  # comma-separated list or '*'
    CORS_SUPPORTS_CREDENTIALS = True

    # Security/Session (if used later)
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)

    # Logging
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
    LOG_DIR = os.getenv("LOG_DIR", "logs")

    # OpenRouter / LLM provider
    OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
    OPENROUTER_BASE_URL = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1/chat/completions")
    OPENROUTER_HTTP_REFERER = os.getenv("OPENROUTER_HTTP_REFERER", "http://localhost:5000")
    OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "anthropic/claude-3-sonnet")


class DevelopmentConfig(Config):
    DEBUG = True
    ENV = "development"


class TestingConfig(Config):
    TESTING = True
    ENV = "testing"
    SQLALCHEMY_DATABASE_URI = os.getenv("TEST_DATABASE_URI", "sqlite:///:memory:")


class ProductionConfig(Config):
    DEBUG = False
    ENV = "production"


config_map = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
}


def create_app(config_name: str | None = None) -> Flask:
    """Application factory pattern.

    Args:
        config_name: one of 'development', 'testing', 'production'. If None, derived from FLASK_ENV or ENV.
    """
    if config_name is None:
        config_name = os.getenv("FLASK_ENV") or os.getenv("ENV", "development")

    app = Flask(__name__)
    app.config.from_object(config_map.get(config_name, DevelopmentConfig))

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)

    # Configure CORS
    _setup_cors(app)

    # Register blueprints/routes
    _register_blueprints(app)

    # Error handlers
    _register_error_handlers(app)

    # Logging
    _setup_logging(app)

    # Health check route
    @app.route("/health", methods=["GET"])
    def health_check():
        return jsonify({"status": "ok", "env": app.config.get("ENV", "unknown")}), 200

    return app


def _setup_cors(app: Flask) -> None:
    origins = app.config.get("CORS_ORIGINS", "*")
    if isinstance(origins, str) and origins != "*":
        origins = [o.strip() for o in origins.split(",") if o.strip()]
    CORS(
        app,
        resources={r"/*": {"origins": origins}},
        supports_credentials=app.config.get("CORS_SUPPORTS_CREDENTIALS", True),
    )


def _register_blueprints(app: Flask) -> None:
    # Import here to avoid circular imports
    try:
        from .routes import api_bp  # Expecting a Blueprint named api_bp
        from .demo_controller import demo_bp  # Demo controller blueprint

        api_prefix = app.config.get("API_PREFIX", "/api")
        app.register_blueprint(api_bp, url_prefix=api_prefix)
        app.register_blueprint(demo_bp, url_prefix=api_prefix)  # Demo endpoints under /api
    except Exception as e:
        app.logger.warning(f"Routes not registered: {e}")


def _register_error_handlers(app: Flask) -> None:
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({"error": "bad_request", "message": str(error)}), 400

    @app.errorhandler(401)
    def unauthorized(error):
        return jsonify({"error": "unauthorized", "message": str(error)}), 401

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"error": "not_found", "message": "Resource not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(error):
        return jsonify({"error": "method_not_allowed", "message": "Method not allowed"}), 405

    @app.errorhandler(422)
    def unprocessable_entity(error):
        return jsonify({"error": "unprocessable_entity", "message": str(error)}), 422

    @app.errorhandler(500)
    def internal_error(error):
        app.logger.exception("Internal server error")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


def _setup_logging(app: Flask) -> None:
    log_level = getattr(logging, app.config.get("LOG_LEVEL", "INFO"), logging.INFO)
    app.logger.setLevel(log_level)

    # Ensure log directory exists
    log_dir = app.config.get("LOG_DIR", "logs")
    try:
        os.makedirs(log_dir, exist_ok=True)
    except Exception:
        # Fallback to stdout only if directory cannot be created
        pass

    # Rotating file handler
    log_path = os.path.join(log_dir, "app.log")
    try:
        file_handler = RotatingFileHandler(log_path, maxBytes=2 * 1024 * 1024, backupCount=5)
        file_handler.setLevel(log_level)
        file_formatter = logging.Formatter(
            "%(asctime)s | %(levelname)s | %(name)s | %(message)s"
        )
        file_handler.setFormatter(file_formatter)
        app.logger.addHandler(file_handler)
    except Exception:
        # If file handler fails, continue with stream handler only
        pass

    # Stream handler (stdout)
    stream_handler = logging.StreamHandler()
    stream_handler.setLevel(log_level)
    stream_formatter = logging.Formatter("%(levelname)s | %(message)s")
    stream_handler.setFormatter(stream_formatter)
    app.logger.addHandler(stream_handler)


# Convenience import for models so migrations and shell can access db/models directly
from . import models  # noqa: E402,F401
