# Shield AI

<div align="center">
  <img src="./mobile/assets/images/shield-ai.jpg" alt="Shield AI Login Demo" width="300" />
  
  **AI-Powered Fraud Detection for Mobile Money**
</div>

---

## Overview

Shield AI is a real-time fraud detection system for Kenyan mobile money transactions. It combines machine learning with a Flutter-based mobile app to provide secure M-Pesa transactions with AI-powered fraud detection.

### Key Features

- **Automatic Backend Startup**: The Flutter app automatically starts the Flask backend server on launch
- **Secure Authentication**: Phone number and PIN-based login with backend validation
- **Real-time Fraud Detection**: AI-powered analysis of transaction patterns
- **M-Pesa STK Push Integration**: Secure mobile money payments with real-time status tracking
- **Cross-platform**: Flutter app runs on Android, iOS, web, and desktop
- **Database Integration**: SQLite database for user and transaction storage

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

**Note:** The Flutter app automatically starts the backend server on launch. No manual backend startup required for development.

Update API base URL in `mobile/lib/src/services/api_service.dart` if running on non-standard port.

## Authentication

Shield AI implements secure user authentication:

- **User Registration**: Create account with full name, phone number, and PIN
- **Login**: Authenticate using phone number and PIN against backend database
- **Protected Routes**: All transaction and fraud detection endpoints require valid credentials
- **PIN Security**: PINs are hashed using werkzeug.security before storage

### API Endpoints

- `POST /api/login` - User authentication
- `POST /api/users` - User registration
- `POST /api/check-fraud` - Fraud detection (authenticated)
- `GET /api/users/{phone}/transactions` - Transaction history (authenticated)
- `GET /api/health` - Health check

### M-Pesa STK Push Integration

Shield AI integrates with M-Pesa's STK Push API for secure mobile money payments:

#### Backend Implementation
- **STK Push Service**: `backend/app/mpesa/stk_push.py` - Handles payment initiation and status queries
- **Core Service**: `backend/app/mpesa/mpesa_service.py` - Shared M-Pesa functionality (auth, validation, logging)
- **Callback Handler**: `backend/app/mpesa/callbacks.py` - Processes M-Pesa payment confirmations
- **Transaction Models**: `backend/app/mpesa/models.py` - M-Pesa transaction data structures

#### API Endpoints
- `POST /api/stkpush` - Initiate STK Push payment
- `POST /api/callback` - Handle M-Pesa payment callbacks
- `GET /api/transactions/{id}` - Query specific transaction status
- `GET /api/transactions?user_id={id}` - Get user's M-Pesa transactions

#### Payment Flow
1. **Initiation**: App calls `POST /api/stkpush` with payment details
2. **STK Push**: Backend sends request to Safaricom M-Pesa API
3. **User Interaction**: M-Pesa USSD prompt appears on user's phone
4. **Callback**: M-Pesa sends payment result to backend callback URL
5. **Status Update**: Transaction status updated in database
6. **Notification**: App can query transaction status for real-time updates

#### Configuration
Required environment variables for M-Pesa integration:
```bash
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_BUSINESS_SHORTCODE=your_shortcode
MPESA_PASSKEY=your_passkey
MPESA_CALLBACK_URL=https://your-domain/api/callback
```

#### Flutter Integration
- **Service**: `mobile/lib/src/services/mpesa_sync_service.dart` - STK Push and transaction management
- **Models**: `mobile/lib/src/models/mpesa_models.dart` - STK Push results and transaction status
- **Methods**:
  - `initiateStkPush()` - Start payment process
  - `queryTransactionStatus()` - Check payment status
  - `getUserMpesaTransactions()` - Get transaction history

#### Error Handling
- Network timeouts and retries
- Invalid payment amounts validation
- Phone number format validation
- Transaction status polling
- Comprehensive logging for debugging

#### Security Features
- OAuth 2.0 authentication with M-Pesa API
- Secure callback URL validation
- Transaction amount limits
- User authentication required for all operations
- Encrypted communication with backend

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

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for detailed information on:
- Development setup
- Code standards
- Pull request process
- Reporting issues

## License & Ownership

Shield AI is proprietary software. See our [License Agreement](LICENSE) for full terms.

### Additional Documentation
- **[Code of Conduct](CODE_OF_CONDUCT.md)** - Community guidelines and standards
- **[Authors](AUTHORS)** - Project contributors and ownership
- **[Notice](NOTICE)** - Legal notices and third-party components

### Contact Information
- **General Inquiries**: info@shieldai.com
- **Technical Support**: support@shieldai.com
- **Licensing**: licensing@shieldai.com
- **Conduct Issues**: conduct@shieldai.com

---

**Copyright © 2025 Shield AI. All rights reserved.**

**Last Updated:** November 2025
