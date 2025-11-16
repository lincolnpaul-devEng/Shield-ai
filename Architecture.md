# Shield AI - Architecture Documentation

## Project Overview
A real-time fraud detection system for Kenyan mobile money transactions using Flutter (frontend) and Flask (backend) with AI/ML capabilities.

## Tech Stack
- **Frontend**: Flutter (Dart) with Provider state management
- **Backend**: Flask (Python) with SQLAlchemy
- **AI/ML**: Scikit-learn for fraud detection
- **Database**: SQLite (development), PostgreSQL (production)
- **Communication**: REST API with JSON

## Project Structure
shield ai/
├── backend/
│ ├── app/
│ │ ├── init.py # Flask app factory
│ │ ├── models.py # SQLAlchemy database models
│ │ ├── routes.py # API endpoints
│ │ └── fraud_detector.py # Core AI/ML logic
│ ├── requirements.txt # Python dependencies
│ └── run.py # Application entry point
├── mobile/
│ ├── lib/
│ │ ├── src/
│ │ │ ├── screens/ # UI pages
│ │ │ ├── services/ # API clients & business logic
│ │ │ ├── models/ # Data classes
│ │ │ └── widgets/ # Reusable UI components
│ │ └── main.dart # App entry point
│ └── pubspec.yaml # Flutter dependencies
└── docs/
└── architecture.md # This file

text

## Core Architecture Principles

### 1. Separation of Concerns
- **Frontend**: Pure UI/UX, no business logic
- **Services**: API communication and data transformation
- **Backend**: Business logic, data persistence, AI processing
## AI API Integration (OpenRouter)
- **Provider**: OpenRouter API
- **Model**: `anthropic/claude-3-sonnet` (recommended for reasoning)
- **Alternative**: `google/gemini-pro-1.5` or `openai/gpt-4`
- **Base URL**: `https://openrouter.ai/api/v1/chat/completions`
- **Headers**: Requires `Authorization: Bearer [KEY]` and `HTTP-Referer: [YOUR_SITE]`
### 2. Data Flow
User Action → Flutter Service → Flask API → Fraud Detection → Response → UI Update

text

### 3. Error Handling Strategy
- Frontend: User-friendly error messages with retry options
- Backend: Structured JSON error responses with codes
- ML: Fallback to rule-based detection if model fails

## API Contract

### Base URL: `http://localhost:5000/api`

#### POST `/check-fraud`
**Request:**
```json
{
  "user_id": "string",
  "transaction": {
    "amount": 15000.0,
    "recipient": "254712345678",
    "timestamp": "2024-01-15T14:30:00Z",
    "location": "Nairobi, Kenya"
  }
}
Response:

json
{
  "is_fraud": true,
  "confidence": 0.87,
  "action_required": true,
  "reason": "Amount significantly higher than user's historical average"
}
GET /users/<user_id>/transactions
Response:

json
{
  "transactions": [
    {
      "amount": 500.0,
      "recipient": "254711223344",
      "timestamp": "2024-01-15T10:30:00Z",
      "is_fraudulent": false
    }
  ]
}
AI/ML Architecture
Fraud Detection Pipeline
Feature Extraction: Amount, time, location, user history patterns

Model Prediction: Isolation Forest for anomaly detection

Rule-Based Overrides: Business rules (e.g., first-time large transfers)

Confidence Scoring: Probability-based decision making

Model Features
Transaction amount deviation from user average

Time of day anomaly

Recipient novelty score

Frequency of transactions

Geographical distance from normal locations

State Management (Flutter)
Provider Structure
UserProvider: Manages user authentication and profile

TransactionProvider: Handles transaction history and fraud alerts

FraudProvider: Manages fraud detection state and notifications

Key Services
ApiService: HTTP client for backend communication

NotificationService: Local push notifications for fraud alerts

FraudService: Business logic for handling fraud detection results

Database Schema
Users Table
id (Primary Key)

phone (String, Unique)

normal_spending_limit (Float)

created_at (DateTime)

Transactions Table
id (Primary Key)

user_id (Foreign Key)

amount (Float)

recipient (String)

timestamp (DateTime)

location (String)

is_fraudulent (Boolean)

fraud_confidence (Float)

Security Considerations
Data Protection
All API communications use HTTPS

Sensitive data encrypted at rest

User authentication required for all endpoints

Fraud Prevention
Rate limiting on API endpoints

Suspicious activity logging

Regular model retraining with new fraud patterns

Demo Data Strategy
User Personas
Student Mary: Daily transactions < 2,000 KSH

Business David: Transactions 5,000-50,000 KSH

Mama Mboga Sarah: Small frequent transactions

Demo Scenarios
Normal transaction pattern establishment

Sudden large amount fraud attempt

Unusual location-based transaction

Multiple rapid transactions fraud pattern

Development Workflow
1. Backend First
Implement API endpoints with mock responses

Build fraud detection logic with test data

Create database models and relationships

2. Frontend Integration
Build UI components with mock data

Connect to backend APIs

Implement real-time fraud alerts

3. AI/ML Integration
Train initial model with synthetic data

Integrate real-time prediction

Implement model performance monitoring

Testing Strategy
Backend Tests
Unit tests for fraud detection logic

Integration tests for API endpoints

Model validation tests

Frontend Tests
Widget tests for UI components

Integration tests for user flows

Service tests for API communication

Deployment Considerations
Development
SQLite database

Local Flask server

Hot-reload Flutter development

Production
PostgreSQL database

Gunicorn WSGI server

Flutter web deployment or mobile app stores

Success Metrics
Fraud detection accuracy > 90%

False positive rate < 5%

Response time < 2 seconds

User intervention rate < 10% of transactions

