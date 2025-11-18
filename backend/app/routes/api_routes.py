from flask import Blueprint, jsonify, request, current_app
from datetime import datetime
from ..models import User, Transaction
from ..fraud_detector import FraudDetector

api_bp = Blueprint("api", __name__)


@api_bp.route("/health", methods=["GET"])
def health():
    try:
        # Check database connection by querying users table
        User.query.limit(1).all()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        current_app.logger.exception("Database health check failed")
        return jsonify({"status": "unhealthy", "database": "disconnected", "error": str(e)}), 500


@api_bp.route("/login", methods=["POST"])
def login():
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        phone = payload.get('phone')
        pin = payload.get('pin')

        if not phone or not pin:
            return jsonify({"error": "bad_request", "message": "Phone and PIN are required"}), 400

        # Find user by phone
        user = User.query.filter_by(phone=phone).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Check PIN
        if not user.check_pin(pin):
            return jsonify({"error": "unauthorized", "message": "Invalid PIN"}), 401

        return jsonify(user.to_dict()), 200

    except Exception as e:
        current_app.logger.exception("Error in /login")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/check-fraud", methods=["POST"])
def check_fraud():
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        user_id = payload.get('user_id')
        pin = payload.get('pin')
        transaction_data = payload.get('transaction', {})

        if not user_id or not pin or not transaction_data:
            return jsonify({"error": "bad_request", "message": "Missing user_id, pin, or transaction data"}), 400

        required_fields = ['amount', 'recipient', 'timestamp']
        for field in required_fields:
            if field not in transaction_data:
                return jsonify({"error": "bad_request", "message": f"Missing required field: {field}"}), 400

        # Get user and their transaction history
        user = User.query.filter_by(phone=user_id).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Verify PIN
        if not user.check_pin(pin):
            return jsonify({"error": "unauthorized", "message": "Invalid PIN"}), 401

        # Get recent transaction history for fraud detection
        history = Transaction.history_for_user(user.id, limit=50)
        history_data = [tx.to_dict() for tx in history]

        # Perform fraud detection
        detector = FraudDetector()
        fraud_result = detector.detect_fraud(history_data, transaction_data)

        # Save transaction to database
        try:
            from . import db
            transaction = Transaction(
                user_id=user.id,
                amount=float(transaction_data['amount']),
                recipient=str(transaction_data['recipient']),
                timestamp=datetime.fromisoformat(transaction_data['timestamp'].replace('Z', '+00:00')),
                location=transaction_data.get('location'),
                is_fraudulent=fraud_result['is_fraud'],
                fraud_confidence=fraud_result['confidence']
            )
            db.session.add(transaction)
            db.session.commit()

            # Add transaction ID to response
            fraud_result['transaction_id'] = transaction.id

        except Exception as db_error:
            from . import db
            db.session.rollback()
            current_app.logger.error(f"Database error saving transaction: {db_error}")
            # Still return fraud result even if save fails
            fraud_result['warning'] = 'Transaction detected but not saved to database'

        return jsonify(fraud_result), 200

    except Exception as e:
        from . import db
        current_app.logger.exception("Error in /check-fraud")
        db.session.rollback()
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/users/<string:user_id>/transactions", methods=["GET"])
def get_transactions(user_id: str):
    try:
        # Get PIN from query params
        pin = request.args.get('pin')
        if not pin:
            return jsonify({"error": "bad_request", "message": "PIN is required"}), 400

        # Find user by phone number
        user = User.query.filter_by(phone=user_id).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Verify PIN
        if not user.check_pin(pin):
            return jsonify({"error": "unauthorized", "message": "Invalid PIN"}), 401

        # Get query parameters
        limit = request.args.get('limit', type=int)
        offset = request.args.get('offset', 0, type=int)

        # Query transactions
        query = Transaction.query.filter_by(user_id=user.id).order_by(Transaction.timestamp.desc())

        if limit:
            query = query.limit(limit)
        if offset:
            query = query.offset(offset)

        transactions = query.all()
        transaction_data = [tx.to_dict() for tx in transactions]

        return jsonify({"transactions": transaction_data}), 200

    except Exception as e:
        current_app.logger.exception("Error in /users/<user_id>/transactions")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/users", methods=["POST"])
def create_user():
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        full_name = payload.get('full_name')
        phone = payload.get('phone')
        pin = payload.get('pin')

        if not full_name or not phone or not pin:
            return jsonify({"error": "bad_request", "message": "Full name, phone, and PIN are required"}), 400

        # Check if user already exists
        existing_user = User.query.filter_by(phone=phone).first()
        if existing_user:
            return jsonify({"error": "conflict", "message": "User already exists"}), 409

        # Create new user
        user = User(
            full_name=full_name,
            phone=phone
        )
        user.set_pin(pin)

        from . import db
        db.session.add(user)
        db.session.commit()

        return jsonify(user.to_dict()), 201

    except Exception as e:
        from . import db
        current_app.logger.exception("Error in /users")
        db.session.rollback()
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500
