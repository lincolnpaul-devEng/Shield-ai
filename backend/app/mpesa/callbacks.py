import json
from flask import current_app, request, jsonify
from .. import db
from .models import MpesaTransaction


class MpesaCallbackHandler:
    """Handler for M-Pesa callback responses"""

    def handle_stk_push_callback(self, callback_data):
        """Handle STK Push callback from Safaricom"""

        try:
            # Extract callback data
            stk_callback = callback_data.get('Body', {}).get('stkCallback', {})

            if not stk_callback:
                current_app.logger.error("Invalid callback data: missing stkCallback")
                return {"error": "Invalid callback data"}, 400

            merchant_request_id = stk_callback.get('MerchantRequestID')
            checkout_request_id = stk_callback.get('CheckoutRequestID')
            result_code = stk_callback.get('ResultCode')
            result_desc = stk_callback.get('ResultDesc')
            callback_metadata = stk_callback.get('CallbackMetadata', {})

            # Find the transaction
            transaction = MpesaTransaction.query.filter_by(
                checkout_request_id=checkout_request_id
            ).first()

            if not transaction:
                current_app.logger.error(f"Transaction not found for CheckoutRequestID: {checkout_request_id}")
                return {"error": "Transaction not found"}, 404

            # Store callback data
            transaction.callback_data = json.dumps(callback_data)

            # Process based on result code
            if result_code == 0:
                # Success - extract payment details
                amount = None
                receipt_number = None
                transaction_date = None
                phone_number = None

                if 'Item' in callback_metadata:
                    for item in callback_metadata['Item']:
                        if item.get('Name') == 'Amount':
                            amount = item.get('Value')
                        elif item.get('Name') == 'MpesaReceiptNumber':
                            receipt_number = item.get('Value')
                        elif item.get('Name') == 'TransactionDate':
                            transaction_date = item.get('Value')
                        elif item.get('Name') == 'PhoneNumber':
                            phone_number = item.get('Value')

                # Update transaction
                transaction.mark_completed(receipt_number, result_desc)
                transaction.mpesa_receipt_number = receipt_number

                current_app.logger.info(
                    f"STK Push successful: {receipt_number}, amount: {amount}, "
                    f"user: {transaction.user_id}"
                )

                # TODO: Here you could trigger additional business logic
                # like updating user balance, sending notifications, etc.

            else:
                # Failed or cancelled
                if result_code == 1032:
                    transaction.mark_cancelled(result_desc)
                else:
                    transaction.mark_failed(result_code, result_desc)

                current_app.logger.warning(
                    f"STK Push failed: {result_code} - {result_desc}, "
                    f"user: {transaction.user_id}"
                )

            # Save changes
            db.session.commit()

            return {"success": True, "message": "Callback processed successfully"}, 200

        except Exception as e:
            current_app.logger.exception(f"Error processing STK Push callback: {e}")
            db.session.rollback()
            return {"error": "Internal server error"}, 500

    def validate_callback(self, callback_data):
        """Basic validation of callback data"""
        required_fields = ['Body']
        for field in required_fields:
            if field not in callback_data:
                return False, f"Missing required field: {field}"

        body = callback_data.get('Body', {})
        if 'stkCallback' not in body:
            return False, "Missing stkCallback in Body"

        stk_callback = body.get('stkCallback', {})
        required_stk_fields = ['MerchantRequestID', 'CheckoutRequestID', 'ResultCode', 'ResultDesc']
        for field in required_stk_fields:
            if field not in stk_callback:
                return False, f"Missing required field in stkCallback: {field}"

        return True, None