# Shield AI

<div align="center">
  <img src="./assets/shield-ai-demo.jpg" alt="Shield AI Login Demo" width="300" />
</div>

A real-time fraud detection system for Kenyan mobile money transactions.

Tech stack:
- Frontend: Flutter with Provider
- Backend: Flask with SQLAlchemy
- AI/ML: scikit-learn (IsolationForest baseline)
- DB: SQLite (dev), PostgreSQL (prod)
- API: REST/JSON

Repository layout
- backend/ — Flask API, models, fraud detection
- mobile/ — Flutter app (Android, iOS, web, desktop targets)
- docs/ — Architecture and API documentation

Quickstart
1) Prerequisites
- Python 3.10+
- Flutter SDK 3.x
- Android Studio/Xcode for mobile targets

2) Backend setup
- cd backend
- python -m venv .venv && .venv/Scripts/activate (Windows) or source .venv/bin/activate (Unix)
- pip install -r requirements.txt
- copy .env.example to .env and adjust values
- python run.py
API default base: http://localhost:5000/api

3) Mobile setup
- cd mobile
- flutter pub get
- flutter run -d chrome (web) or choose a device
Configure API base URL in mobile/lib/src/services/api_service.dart if needed.

Environment variables
See .env.example at root or backend/.env.example for available settings: database URI, OpenRouter keys, API prefix, etc.

Development workflow
- Implement backend endpoints first with mock data
- Build Flutter UI and connect to API
- Integrate ML model and iterate

Testing
- Backend: pytest recommended
- Frontend: flutter test

Deployment
- Backend: Gunicorn + PostgreSQL
- Frontend: app stores or Flutter web hosting

License
Proprietary
