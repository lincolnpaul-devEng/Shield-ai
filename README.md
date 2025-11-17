# Shield AI

<div align="center">
  <img src="./mobile/assets/images/shield-ai.jpg" alt="Shield AI Login Demo" width="300" />
  
  **AI-Powered Fraud Detection for Mobile Money**
</div>

---

## Overview

Shield AI is a real-time fraud detection system for Kenyan mobile money transactions. It combines machine learning with a Flutter-based mobile app to provide secure M-Pesa transactions with AI-powered fraud detection.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Frontend** | Flutter with Provider |
| **Backend** | Flask with SQLAlchemy |
| **AI/ML** | scikit-learn (IsolationForest baseline) |
| **Database** | SQLite (dev), PostgreSQL (prod) |
| **API** | REST/JSON |

## Repository Structure

```
Shield-ai/
├── backend/          # Flask API, ML models, fraud detection
├── mobile/           # Flutter app (Android, iOS, web, desktop)
├── docs/             # Architecture and API documentation
├── assets/           # Images and static assets
└── README.md         # This file
```

## Quick Start

### Prerequisites

- Python 3.10+
- Flutter SDK 3.x
- Android Studio/Xcode (for mobile targets)
- Git

### Backend Setup

```bash
cd backend
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On Unix/macOS:
source .venv/bin/activate

pip install -r requirements.txt
cp .env.example .env  # Update .env with your configuration
python run.py
```

**API Base URL:** `http://localhost:5000/api`

### Mobile Setup

```bash
cd mobile
flutter pub get
flutter run -d chrome    # For web
# or select your target device
```

Update API base URL in `mobile/lib/src/services/api_service.dart` if running on non-standard port.

## Configuration

### Environment Variables

Configuration files:
- `.env.example` (root directory)
- `backend/.env.example`

Available settings:
- Database URI
- OpenRouter API keys
- API prefix configuration
- Feature flags

## Development Workflow

1. **Backend Development**
   - Implement endpoints with mock data
   - Test with pytest
   - Document API contracts

2. **Frontend Development**
   - Build Flutter UI components
   - Connect to backend API
   - Implement state management with Provider

3. **ML Integration**
   - Train/refine fraud detection models
   - Validate accuracy metrics
   - Integrate into backend

## Testing

### Backend

```bash
cd backend
pytest
```

### Frontend

```bash
cd mobile
flutter test
```

## Deployment

### Backend

- **Server:** Gunicorn
- **Database:** PostgreSQL
- **Container:** Docker (recommended)

### Frontend

- **iOS:** Apple App Store
- **Android:** Google Play Store
- **Web:** Flutter web hosting (Firebase, Vercel, etc.)

## Project Structure Details

- **backend/app/** - Application code, models, routes
- **mobile/lib/src/** - Dart source code organized by feature
- **mobile/android/** - Android-specific configuration
- **mobile/ios/** - iOS-specific configuration
- **docs/** - Architecture decisions and API documentation

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

Proprietary - All rights reserved

---

**Last Updated:** November 2025
