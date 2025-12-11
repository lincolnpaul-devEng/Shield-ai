from datetime import datetime
from . import db
from werkzeug.security import generate_password_hash, check_password_hash


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(128), nullable=False)
    phone = db.Column(db.String(32), unique=True, nullable=False, index=True)
    pin_hash = db.Column(db.String(256), nullable=False)
    mpesa_balance = db.Column(db.Float, default=0.0, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, index=True)

    __table_args__ = (
        db.CheckConstraint('length(phone) >= 10', name='phone_length_check'),
    )

    transactions = db.relationship(
        "Transaction",
        backref="user",
        lazy="dynamic",
        cascade="all, delete-orphan",
        order_by="desc(Transaction.timestamp)",
    )

    def set_pin(self, pin):
        self.pin_hash = generate_password_hash(pin)

    def check_pin(self, pin):
        return check_password_hash(self.pin_hash, pin)

    def to_dict(self, include_transactions: bool = False, limit: int | None = None):
        data = {
            "id": self.id,
            "full_name": self.full_name,
            "phone": self.phone,
            "mpesa_balance": float(self.mpesa_balance) if self.mpesa_balance is not None else 0.0,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
        if include_transactions:
            q = self.transactions
            if limit is not None:
                q = q.limit(limit)
            data["transactions"] = [t.to_dict() for t in q.all()]
        return data

    def recent_transactions(self, limit: int = 20):
        return self.transactions.limit(limit).all()

    def transactions_between(self, start: datetime, end: datetime):
        return self.transactions.filter(
            Transaction.timestamp >= start, Transaction.timestamp <= end
        ).all()


class Transaction(db.Model):
    __tablename__ = "transactions"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    amount = db.Column(db.Float, nullable=False)
    recipient = db.Column(db.String(64), nullable=False, index=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, index=True)
    location = db.Column(db.String(128), nullable=True)
    is_fraudulent = db.Column(db.Boolean, default=False, nullable=False, index=True)
    fraud_confidence = db.Column(db.Float, default=0.0, nullable=False)

    __table_args__ = (
        db.CheckConstraint('amount > 0', name='amount_positive'),
        db.CheckConstraint('fraud_confidence >= 0.0 AND fraud_confidence <= 1.0', name='confidence_range'),
        db.CheckConstraint('length(recipient) >= 10', name='recipient_length_check'),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "amount": float(self.amount) if self.amount is not None else None,
            "recipient": self.recipient,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "location": self.location,
            "is_fraudulent": bool(self.is_fraudulent),
            "fraud_confidence": float(self.fraud_confidence) if self.fraud_confidence is not None else None,
        }

    @staticmethod
    def history_for_user(user_id: int, limit: int | None = None):
        q = Transaction.query.filter_by(user_id=user_id).order_by(Transaction.timestamp.desc())
        if limit is not None:
            q = q.limit(limit)
        return q.all()

class UserBudgetPlan(db.Model):
    __tablename__ = "user_budget_plans"

    id = db.Column(db.String(36), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    plan_name = db.Column(db.String(128), nullable=False)
    plan_description = db.Column(db.Text, nullable=True)
    monthly_income = db.Column(db.Float, nullable=False)
    savings_goal = db.Column(db.Float, nullable=True)
    savings_period_months = db.Column(db.Integer, nullable=True)
    allocations = db.Column(db.JSON, nullable=False)  # Store category allocations as JSON
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    __table_args__ = (
        db.CheckConstraint('monthly_income > 0', name='income_positive'),
        db.CheckConstraint('savings_goal >= 0', name='savings_goal_non_negative'),
        db.CheckConstraint('savings_period_months > 0', name='savings_period_positive'),
    )

    # Relationship with User
    user = db.relationship("User", backref="budget_plans")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "plan_name": self.plan_name,
            "plan_description": self.plan_description,
            "monthly_income": float(self.monthly_income) if self.monthly_income is not None else None,
            "savings_goal": float(self.savings_goal) if self.savings_goal is not None else None,
            "savings_period_months": self.savings_period_months,
            "allocations": self.allocations,
            "is_active": bool(self.is_active),
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    @staticmethod
    def get_active_plan_for_user(user_id: int):
        return UserBudgetPlan.query.filter_by(
            user_id=user_id,
            is_active=True
        ).order_by(UserBudgetPlan.updated_at.desc()).first()

    @staticmethod
    def get_all_plans_for_user(user_id: int):
        return UserBudgetPlan.query.filter_by(user_id=user_id).order_by(
            UserBudgetPlan.updated_at.desc()
        ).all()


# Import M-Pesa models to ensure they are registered with SQLAlchemy
from .mpesa import models as mpesa_models  # noqa: E402,F401
