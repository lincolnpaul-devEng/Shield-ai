# M-Pesa Integration Architecture

## M-Pesa API Strategy for Shield AI
### **1. Backend M-Pesa Service** (`app/mpesa_service.py`):
```python
import requests
import base64
from datetime import datetime
import hashlib

class MpesaService:
    def __init__(self):
        self.consumer_key = os.getenv('MPESA_CONSUMER_KEY')
        self.consumer_secret = os.getenv('MPESA_CONSUMER_SECRET')
        self.business_shortcode = os.getenv('MPESA_BUSINESS_SHORTCODE')
        self.passkey = os.getenv('MPESA_PASSKEY')
        self.callback_url = os.getenv('MPESA_CALLBACK_URL')
        
    def get_access_token(self):
        """Get OAuth access token from Safaricom"""
        url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
        auth = base64.b64encode(f"{self.consumer_key}:{self.consumer_secret}".encode()).decode()
        
        headers = {"Authorization": f"Basic {auth}"}
        response = requests.get(url, headers=headers)
        return response.json().get('access_token')
    
    def initiate_stk_push(self, phone_number, amount, account_reference, description):
        """Initiate STK Push to user's phone"""
        access_token = self.get_access_token()
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        password = base64.b64encode(
            f"{self.business_shortcode}{self.passkey}{timestamp}".encode()
        ).decode()
        
        payload = {
            "BusinessShortCode": self.business_shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": amount,
            "PartyA": phone_number,
            "PartyB": self.business_shortcode,
            "PhoneNumber": phone_number,
            "CallBackURL": self.callback_url,
            "AccountReference": account_reference,
            "TransactionDesc": description
        }
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        response = requests.post(
            "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
            json=payload,
            headers=headers
        )
        
        return response.json()
    
    def handle_callback(self, callback_data):
        """Handle STK Push callback from Safaricom"""
        # Process payment result
        result_code = callback_data.get('Body', {}).get('stkCallback', {}).get('ResultCode')
        result_desc = callback_data.get('Body', {}).get('stkCallback', {}).get('ResultDesc')
        
        if result_code == 0:
            # Payment successful
            return {"status": "success", "message": result_desc}
        else:
            # Payment failed
            return {"status": "failed", "message": result_desc}           
### Primary API: M-Pesa Express (STK Push)
- **Endpoint**: `/mpesa/stkpush/v1/processrequest`
- **Purpose**: Initiate payments from user's phone
- **Flow**: App → Shield AI Backend → Safaricom → User's Phone (USSD) → Callback

### Secondary API: Transaction Status
- **Endpoint**: `/mpesa/transactionstatus/v1/query`
- **Purpose**: Check payment status
- **Use Case**: Verify completed transactions

### Sandbox vs Production

#### Sandbox Credentials (Development):
```bash
Business ShortCode: 174379
Test Phone Numbers: 254708374149, 254712345678
Test Amount Range: 1-100 KSH
Callback URL: http://your-ngrok-url/api/mpesa/callback