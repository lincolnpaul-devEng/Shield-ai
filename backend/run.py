import os
import sys
from app import create_app, db
from app.seed_data import seed_database, clear_database

def init_db():
    """Initialize the database."""
    print("Initializing database...")
    with create_app().app_context():
        db.create_all()
        print("Database initialized!")

def seed_db():
    """Seed the database with demo data."""
    with create_app().app_context():
        seed_database()

def clear_db():
    """Clear all data from database."""
    with create_app().app_context():
        clear_database()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        command = sys.argv[1]
        if command == "init-db":
            init_db()
        elif command == "seed-db":
            seed_db()
        elif command == "clear-db":
            clear_db()
        elif command == "reset-db":
            with create_app().app_context():
                clear_database()
                db.create_all()
                seed_database()
            print("Database reset complete!")
        else:
            print("Usage: python run.py [init-db|seed-db|clear-db|reset-db]")
            sys.exit(1)
    else:
        # Normal server run
        env = os.getenv("FLASK_ENV") or os.getenv("ENV", "development")
        app = create_app(env)

        # Auto-initialize database in development
        if env == "development":
            with app.app_context():
                db.create_all()

        host = os.getenv("HOST", "0.0.0.0")
        port = int(os.getenv("PORT", "5000"))
        debug = env == "development"
        print(f"Starting server on {host}:{port} (debug={debug})")
        app.run(host=host, port=port, debug=debug)
