from flask import Blueprint, request, jsonify, current_app
from .. import db
from ..models import User
from ..mpesa.models import MpesaTransaction
from ..mpesa.stk_push import StkPushService
from ..mpesa.callbacks import MpesaCallbackHandler

mpesa_bp = Blueprint("mpesa", __name__)


@mpesa_bp.route("/stkpush", methods=["POST"])
def initiate_stk_push():
    """Initiate M-Pesa STK Push payment"""
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        required_fields = ['user_id', 'phone_number', 'amount', 'account_reference']
        for field in required_fields:
            if field not in payload:
                return jsonify({"error": "bad_request", "message": f"Missing required field: {field}"}), 400

        user_id = payload['user_id']
        phone_number = payload['phone_number']
        amount = float(payload['amount'])
        account_reference = payload['account_reference']
        description = payload.get('description', f"Payment for {account_reference}")

        # Validate amount
        if amount <= 0:
            return jsonify({"error": "bad_request", "message": "Amount must be greater than 0"}), 400

        # Validate phone number format (Kenyan numbers)
        if not phone_number.startswith('254') or len(phone_number) != 12:
            return jsonify({"error": "bad_request", "message": "Invalid phone number format. Use 254XXXXXXXXX"}), 400

        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Initialize STK Push service
        stk_service = StkPushService()

        # Initiate payment
        result = stk_service.initiate_stk_push(
            user_id=user_id,
            phone_number=phone_number,
            amount=amount,
            account_reference=account_reference,
            description=description
        )

        return jsonify(result), 200

    except ValueError as e:
        return jsonify({"error": "bad_request", "message": str(e)}), 400
    except Exception as e:
        current_app.logger.exception("Error in /stkpush")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@mpesa_bp.route("/callback", methods=["POST"])
def mpesa_callback():
    """Handle M-Pesa callback"""
    try:
        callback_data = request.get_json(silent=True)

        if not callback_data:
            current_app.logger.error("No callback data received")
            return jsonify({"error": "bad_request", "message": "No data received"}), 400

        current_app.logger.info(f"M-Pesa callback received: {callback_data}")

        # Initialize callback handler
        handler = MpesaCallbackHandler()

        # Validate callback data
        is_valid, error_msg = handler.validate_callback(callback_data)
        if not is_valid:
            current_app.logger.error(f"Invalid callback data: {error_msg}")
            return jsonify({"error": "bad_request", "message": error_msg}), 400

        # Process the callback
        result, status_code = handler.handle_stk_push_callback(callback_data)

        return jsonify(result), status_code

    except Exception as e:
        current_app.logger.exception("Error processing M-Pesa callback")
        return jsonify({"error": "internal_server_error", "message": "Callback processing failed"}), 500


@mpesa_bp.route("/transactions/<int:transaction_id>", methods=["GET"])
def get_transaction_status(transaction_id: int):
    """Get status of a specific M-Pesa transaction"""
    try:
        transaction = MpesaTransaction.query.get(transaction_id)
        if not transaction:
            return jsonify({"error": "not_found", "message": "Transaction not found"}), 404

        return jsonify({"transaction": transaction.to_dict()}), 200

    except Exception as e:
        current_app.logger.exception("Error getting transaction status")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@mpesa_bp.route("/transactions", methods=["GET"])
def get_user_transactions():
    """Get M-Pesa transactions for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({"error": "bad_request", "message": "user_id parameter is required"}), 400

        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Get query parameters
        limit = request.args.get('limit', 20, type=int)
        offset = request.args.get('offset', 0, type=int)
        status = request.args.get('status')

        # Build query
        query = MpesaTransaction.query.filter_by(user_id=user_id)
        if status:
            query = query.filter_by(status=status)

        query = query.order_by(MpesaTransaction.created_at.desc())

        if limit:
            query = query.limit(limit)
        if offset:
            query = query.offset(offset)

        transactions = query.all()
        transaction_data = [tx.to_dict() for tx in transactions]

        return jsonify({"transactions": transaction_data}), 200

    except Exception as e:
        current_app.logger.exception("Error getting user transactions")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500