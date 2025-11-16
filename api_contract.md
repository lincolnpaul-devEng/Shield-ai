## API Endpoints

POST /api/check-fraud
Request: { "user_id": "string", "transaction": { "amount": float, "recipient": "string", "timestamp": "ISOstring" } }
Response: { "is_fraud": boolean, "confidence": float, "action_required": boolean }

GET /api/users/<user_id>/transactions
Response: [{ "amount": float, "recipient": "string", "timestamp": "string", "is_fraudulent": boolean }]