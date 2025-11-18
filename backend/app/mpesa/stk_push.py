import os
from datetime import datetime
from flask import current_app
from .. import db
from .models import MpesaTransaction
from .mpesa_service import MpesaService


class StkPushService(MpesaService):
    """Service for handling M-Pesa STK Push operations"""

    def __init__(self):
        super().__init__()
        # Additional STK Push specific URLs
        self.stk_query_url = f"{self.base_url}/mpesa/stkpushquery/v1/query"

    def initiate_stk_push(self, user_id: int, phone_number: str, amount: float,
                         account_reference: str, description: str = None):
        """Initiate STK Push to user's phone"""

        try:
            # Validate inputs
            phone_number = self.format_phone_number(phone_number)
            amount = self.validate_amount(amount)

            # Generate password and timestamp
            password, timestamp = self.generate_password()

            # Prepare payload
            payload = {
                "BusinessShortCode": self.business_shortcode,
                "Password": password,
                "Timestamp": timestamp,
                "TransactionType": "CustomerPayBillOnline",
                "Amount": int(amount),  # M-Pesa expects integer
                "PartyA": phone_number,
                "PartyB": self.business_shortcode,
                "PhoneNumber": phone_number,
                "CallBackURL": self.callback_url,
                "AccountReference": account_reference,
                "TransactionDesc": description or f"Payment for {account_reference}"
            }

            # Make STK Push request using core service method
            result = self.make_api_request("POST", self.stk_push_url, payload)

            # Create transaction record
            transaction = MpesaTransaction(
                user_id=user_id,
                merchant_request_id=result.get('MerchantRequestID'),
                checkout_request_id=result.get('CheckoutRequestID'),
                amount=amount,
                phone_number=phone_number,
                account_reference=account_reference,
                transaction_desc=description,
                status="pending"
            )

            db.session.add(transaction)
            db.session.commit()

            # Log the transaction
            self.log_transaction("stk_push_initiated", {
                "user_id": user_id,
                "amount": amount,
                "phone_number": phone_number,
                "checkout_request_id": result.get('CheckoutRequestID'),
                "merchant_request_id": result.get('MerchantRequestID')
            })

            return {
                "success": True,
                "transaction_id": transaction.id,
                "merchant_request_id": result.get('MerchantRequestID'),
                "checkout_request_id": result.get('CheckoutRequestID'),
                "response_code": result.get('ResponseCode'),
                "response_description": result.get('ResponseDescription'),
                "customer_message": result.get('CustomerMessage')
            }

        except requests.RequestException as e:
            current_app.logger.error(f"STK Push request failed: {e}")
            db.session.rollback()
            raise Exception("Failed to initiate payment request")

        except Exception as e:
            current_app.logger.error(f"STK Push error: {e}")
            db.session.rollback()
            raise

    def query_transaction_status(self, checkout_request_id: str):
        """Query the status of a transaction"""
        try:
            # Generate password and timestamp
            password, timestamp = self.generate_password()

            payload = {
                "BusinessShortCode": self.business_shortcode,
                "Password": password,
                "Timestamp": timestamp,
                "CheckoutRequestID": checkout_request_id
            }

            # Make API request using core service
            result = self.make_api_request("POST", self.stk_query_url, payload)

            self.log_transaction("stk_query", {"checkout_request_id": checkout_request_id})
            return result

        except Exception as e:
            self.handle_api_error(e, "STK Push query")
