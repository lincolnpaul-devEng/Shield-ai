from datetime import datetime
from .. import db


class MpesaTransaction(db.Model):
    """M-Pesa transaction model for STK Push and other M-Pesa operations"""

    __tablename__ = "mpesa_transactions"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)

    # M-Pesa specific fields
    merchant_request_id = db.Column(db.String(64), unique=True, nullable=True, index=True)
    checkout_request_id = db.Column(db.String(64), unique=True, nullable=True, index=True)
    mpesa_receipt_number = db.Column(db.String(32), unique=True, nullable=True, index=True)

    # Transaction details
    amount = db.Column(db.Float, nullable=False)
    phone_number = db.Column(db.String(32), nullable=False, index=True)
    account_reference = db.Column(db.String(64), nullable=False)
    transaction_desc = db.Column(db.String(128), nullable=True)

    # Status and result
    result_code = db.Column(db.Integer, nullable=True)
    result_desc = db.Column(db.String(256), nullable=True)
    status = db.Column(db.String(32), default="pending", nullable=False, index=True)  # pending, completed, failed, cancelled

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Callback data (stored as JSON)
    callback_data = db.Column(db.Text, nullable=True)

    __table_args__ = (
        db.CheckConstraint('amount > 0', name='mpesa_amount_positive'),
        db.CheckConstraint('length(phone_number) >= 10', name='mpesa_phone_length_check'),
        db.CheckConstraint("status IN ('pending', 'completed', 'failed', 'cancelled')”, name='mpesa_status_check'),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "merchant_request_id": self.merchant_request_id,
            "checkout_request_id": self.checkout_request_id,
            "mpesa_receipt_number": self.mpesa_receipt_number,
            "amount": float(self.amount) if self.amount is not None else None,
            "phone_number": self.phone_number,
            "account_reference": self.account_reference,
            "transaction_desc": self.transaction_desc,
            "result_code": self.result_code,
            "result_desc": self.result_desc,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    @staticmethod
    def get_by_checkout_request_id(checkout_request_id: str):
        """Get transaction by checkout request ID"""
        return MpesaTransaction.query.filter_by(checkout_request_id=checkout_request_id).first()

    @staticmethod
    def get_pending_transactions():
        """Get all pending transactions"""
        return MpesaTransaction.query.filter_by(status="pending").all()

    def mark_completed(self, receipt_number: str, result_desc: str = "Success"):
        """Mark transaction as completed"""
        self.status = "completed"
        self.mpesa_receipt_number = receipt_number
        self.result_code = 0
        self.result_desc = result_desc

    def mark_failed(self, result_code: int, result_desc: str):
        """Mark transaction as failed"""
        self.status = "failed"
        self.result_code = result_code
        self.result_desc = result_desc

    def mark_cancelled(self, result_desc: str = "Cancelled by user"):
        """Mark transaction as cancelled"""
        self.status = "cancelled"
        self.result_code = 1032  # C2B timeout
        self.result_desc = result_desc