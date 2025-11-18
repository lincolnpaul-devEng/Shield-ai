import os
import base64
import requests
from datetime import datetime, timedelta
from flask import current_app


class MpesaService:
    """Core M-Pesa service with shared functionality for all M-Pesa operations"""

    def __init__(self):
        # Load configuration from environment variables
        self.consumer_key = os.getenv('MPESA_CONSUMER_KEY')
        self.consumer_secret = os.getenv('MPESA_CONSUMER_SECRET')
        self.business_shortcode = os.getenv('MPESA_BUSINESS_SHORTCODE')
        self.passkey = os.getenv('MPESA_PASSKEY')
        self.callback_url = os.getenv('MPESA_CALLBACK_URL')

        # Use sandbox URLs by default, can be overridden for production
        self.base_url = os.getenv('MPESA_BASE_URL', 'https://sandbox.safaricom.co.ke')
        self.oauth_url = f"{self.base_url}/oauth/v1/generate"
        self.stk_push_url = f"{self.base_url}/mpesa/stkpush/v1/processrequest"
        self.stk_query_url = f"{self.base_url}/mpesa/stkpushquery/v1/query"
        self.c2b_register_url = f"{self.base_url}/mpesa/c2b/v1/registerurl"
        self.c2b_simulate_url = f"{self.base_url}/mpesa/c2b/v1/simulate"

        # Validate configuration
        self._validate_config()

        # Cache for access token
        self._access_token = None
        self._token_expires_at = None

    def _validate_config(self):
        """Validate that all required configuration is present"""
        required = [
            'consumer_key', 'consumer_secret', 'business_shortcode',
            'passkey', 'callback_url'
        ]
        missing = [key for key in required if not getattr(self, key)]
        if missing:
            raise ValueError(f"Missing M-Pesa configuration: {', '.join(missing)}")

    def get_access_token(self):
        """Get OAuth access token from Safaricom with caching"""
        # Check if we have a valid cached token
        if self._access_token and self._token_expires_at:
            if datetime.now() < self._token_expires_at:
                return self._access_token

        try:
            # Prepare authentication
            auth = base64.b64encode(
                f"{self.consumer_key}:{self.consumer_secret}".encode()
            ).decode()

            headers = {
                "Authorization": f"Basic {auth}",
                "Content-Type": "application/json"
            }

            # Make request
            response = requests.get(
                self.oauth_url,
                params={"grant_type": "client_credentials"},
                headers=headers,
                timeout=30
            )
            response.raise_for_status()

            data = response.json()
            access_token = data.get('access_token')
            expires_in = data.get('expires_in', 3600)  # Default 1 hour

            if not access_token:
                raise Exception("No access token received from M-Pesa")

            # Cache the token
            self._access_token = access_token
            self._token_expires_at = datetime.now() + timedelta(seconds=expires_in - 60)  # Expire 1 min early

            current_app.logger.info("Successfully obtained M-Pesa access token")
            return access_token

        except requests.RequestException as e:
            current_app.logger.error(f"Failed to get M-Pesa access token: {e}")
            raise Exception("Failed to authenticate with M-Pesa API")

    def generate_password(self, timestamp=None):
        """Generate password for M-Pesa API requests"""
        if timestamp is None:
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

        password_string = f"{self.business_shortcode}{self.passkey}{timestamp}"
        password = base64.b64encode(password_string.encode()).decode()
        return password, timestamp

    def make_api_request(self, method, url, data=None, params=None):
        """Make authenticated API request to M-Pesa"""
        try:
            access_token = self.get_access_token()

            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }

            response = requests.request(
                method=method,
                url=url,
                json=data,
                params=params,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            return response.json()

        except requests.RequestException as e:
            current_app.logger.error(f"M-Pesa API request failed: {e}")
            raise Exception(f"M-Pesa API request failed: {str(e)}")

    def format_phone_number(self, phone_number):
        """Format phone number to international format (254XXXXXXXXX)"""
        phone_number = str(phone_number).strip()

        # Remove any leading + or 00
        if phone_number.startswith('+'):
            phone_number = phone_number[1:]
        elif phone_number.startswith('00'):
            phone_number = phone_number[2:]

        # Ensure it starts with 254
        if phone_number.startswith('0'):
            phone_number = '254' + phone_number[1:]
        elif not phone_number.startswith('254'):
            phone_number = '254' + phone_number

        # Validate length (Kenyan numbers should be 12 digits)
        if len(phone_number) != 12 or not phone_number.isdigit():
            raise ValueError("Invalid phone number format")

        return phone_number

    def validate_amount(self, amount):
        """Validate transaction amount"""
        try:
            amount = float(amount)
            if amount <= 0:
                raise ValueError("Amount must be greater than 0")
            if amount > 150000:  # M-Pesa maximum transaction limit
                raise ValueError("Amount exceeds maximum transaction limit")
            return amount
        except (TypeError, ValueError):
            raise ValueError("Invalid amount format")

    def log_transaction(self, transaction_type, data):
        """Log M-Pesa transaction for auditing"""
        current_app.logger.info(
            f"M-Pesa {transaction_type}: {data}"
        )

    def handle_api_error(self, error, operation):
        """Handle and log M-Pesa API errors"""
        current_app.logger.error(f"M-Pesa {operation} error: {error}")
        # Could implement retry logic, notifications, etc. here
        raise error
