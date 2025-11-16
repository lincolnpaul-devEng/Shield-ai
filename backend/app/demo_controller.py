from flask import Blueprint, jsonify, request
from datetime import datetime, timedelta
import random
from . import db
from .models import User, Transaction
from .fraud_detector import FraudDetector

demo_bp = Blueprint("demo", __name__)

# Demo user configurations
DEMO_USERS = {
    "student_mary": {
        "phone": "+254712345678",
        "name": "Student Mary",
        "normal_limit": 2000.0,
        "typical_amounts": [200, 500, 800, 1200],
        "typical_times": [9, 10, 11, 14, 15, 16, 18, 19],  # Business hours
    },
    "business_david": {
        "phone": "+254798765432",
        "name": "Business David",
        "normal_limit": 50000.0,
        "typical_amounts": [5000, 10000, 15000, 25000, 35000],
        "typical_times": [8, 9, 10, 11, 14, 15, 16, 17],  # Business hours
    },
    "mama_mboga_sarah": {
        "phone": "+254711223344",
        "name": "Mama Mboga Sarah",
        "normal_limit": 5000.0,
        "typical_amounts": [100, 200, 300, 500, 800],
        "typical_times": [6, 7, 8, 12, 13, 17, 18, 19],  # Market hours
    }
}

def _get_or_create_demo_user(user_key: str):
    """Get or create a demo user."""
    user_config = DEMO_USERS[user_key]
    user = User.query.filter_by(phone=user_config["phone"]).first()

    if not user:
        user = User(
            phone=user_config["phone"],
            normal_spending_limit=user_config["normal_limit"]
        )
        db.session.add(user)
        db.session.commit()

    return user

def _generate_normal_transaction(user_key: str, days_ago: int = 0):
    """Generate a normal transaction for demo user."""
    user_config = DEMO_USERS[user_key]
    user = _get_or_create_demo_user(user_key)

    # Random time within typical hours
    hour = random.choice(user_config["typical_times"])
    minute = random.randint(0, 59)

    # Create timestamp
    timestamp = datetime.now() - timedelta(days=days_ago)
    timestamp = timestamp.replace(hour=hour, minute=minute, second=0, microsecond=0)

    # Random recipient (different from user's phone)
    recipient = f"+2547{random.randint(10000000, 99999999)}"

    # Random amount from typical range
    amount = random.choice(user_config["typical_amounts"])

    return {
        "user_id": user.id,
        "amount": amount,
        "recipient": recipient,
        "timestamp": timestamp,
        "location": "Nairobi, Kenya",
        "is_fraudulent": False,
        "fraud_confidence": 0.0
    }

def _inject_fraudulent_transaction(scenario: str, user_key: str):
    """Inject a specific fraudulent transaction based on scenario."""
    user_config = DEMO_USERS[user_key]
    user = _get_or_create_demo_user(user_key)

    base_tx = _generate_normal_transaction(user_key, 0)

    if scenario == "student_large_amount_3am":
        # Student suddenly sends 45,000 KSH at 3 AM
        base_tx.update({
            "amount": 45000.0,
            "timestamp": datetime.now().replace(hour=3, minute=15, second=0, microsecond=0),
            "is_fraudulent": True,
            "fraud_confidence": 0.95
        })

    elif scenario == "business_rapid_transfers":
        # Business account multiple rapid transfers
        transactions = []
        base_time = datetime.now()
        for i in range(3):
            tx = base_tx.copy()
            tx.update({
                "amount": random.choice([15000, 25000, 35000]),
                "timestamp": base_time + timedelta(minutes=i * 2),
                "recipient": f"+2547{random.randint(10000000, 99999999)}",
                "is_fraudulent": True,
                "fraud_confidence": 0.88
            })
            transactions.append(tx)
        return transactions

    elif scenario == "new_recipient_large_amount":
        # New recipient with large amount
        base_tx.update({
            "amount": user_config["normal_limit"] * 2,  # Double normal limit
            "recipient": "+254799999999",  # Completely new recipient
            "is_fraudulent": True,
            "fraud_confidence": 0.82
        })

    # Save transaction(s)
    if isinstance(base_tx, list):
        for tx_data in base_tx:
            tx = Transaction(**tx_data)
            db.session.add(tx)
    else:
        tx = Transaction(**base_tx)
        db.session.add(tx)

    db.session.commit()
    return base_tx if not isinstance(base_tx, list) else base_tx

@demo_bp.route("/demo/reset", methods=["POST"])
def reset_demo_data():
    """Reset all demo data."""
    try:
        # Clear all transactions and users
        Transaction.query.delete()
        User.query.delete()
        db.session.commit()

        # Recreate demo users
        for user_key, config in DEMO_USERS.items():
            user = User(
                phone=config["phone"],
                normal_spending_limit=config["normal_limit"]
            )
            db.session.add(user)

            # Generate 10-15 normal transactions over the past 30 days
            for days_ago in range(30):
                if random.random() < 0.4:  # 40% chance of transaction per day
                    tx_data = _generate_normal_transaction(user_key, days_ago)
                    tx = Transaction(**tx_data)
                    db.session.add(tx)

        db.session.commit()

        return jsonify({
            "status": "success",
            "message": "Demo data reset successfully",
            "users_created": len(DEMO_USERS),
            "transactions_created": Transaction.query.count()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "reset_failed", "message": str(e)}), 500

@demo_bp.route("/demo/inject-fraud", methods=["POST"])
def inject_fraud():
    """Inject a fraudulent transaction."""
    try:
        payload = request.get_json(silent=True) or {}
        scenario = payload.get("scenario")
        user_key = payload.get("user_key", "student_mary")

        if not scenario:
            return jsonify({"error": "bad_request", "message": "scenario is required"}), 400

        if user_key not in DEMO_USERS:
            return jsonify({"error": "bad_request", "message": f"Invalid user_key. Must be one of: {list(DEMO_USERS.keys())}"}), 400

        result = _inject_fraudulent_transaction(scenario, user_key)

        return jsonify({
            "status": "success",
            "message": f"Fraudulent transaction injected for scenario: {scenario}",
            "user": DEMO_USERS[user_key]["name"],
            "transaction": result
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "injection_failed", "message": str(e)}), 500

@demo_bp.route("/demo/status", methods=["GET"])
def get_demo_status():
    """Get demo status and statistics."""
    try:
        users = []
        total_transactions = 0
        total_fraudulent = 0

        for user_key, config in DEMO_USERS.items():
            user = User.query.filter_by(phone=config["phone"]).first()
            if user:
                user_txs = Transaction.query.filter_by(user_id=user.id).all()
                fraudulent_txs = [tx for tx in user_txs if tx.is_fraudulent]

                users.append({
                    "key": user_key,
                    "name": config["name"],
                    "phone": config["phone"],
                    "total_transactions": len(user_txs),
                    "fraudulent_transactions": len(fraudulent_txs),
                    "normal_limit": config["normal_limit"]
                })

                total_transactions += len(user_txs)
                total_fraudulent += len(fraudulent_txs)

        return jsonify({
            "status": "active",
            "total_users": len(users),
            "total_transactions": total_transactions,
            "total_fraudulent": total_fraudulent,
            "fraud_rate": round(total_fraudulent / max(total_transactions, 1) * 100, 2),
            "users": users
        }), 200

    except Exception as e:
        return jsonify({"error": "status_failed", "message": str(e)}), 500

@demo_bp.route("/demo/scenarios", methods=["GET"])
def get_available_scenarios():
    """Get list of available demo scenarios."""
    scenarios = {
        "student_large_amount_3am": {
            "description": "Student suddenly sends 45,000 KSH at 3 AM",
            "user_key": "student_mary",
            "expected_fraud": True
        },
        "business_rapid_transfers": {
            "description": "Business account multiple rapid transfers",
            "user_key": "business_david",
            "expected_fraud": True
        },
        "new_recipient_large_amount": {
            "description": "New recipient with large amount",
            "user_key": "business_david",
            "expected_fraud": True
        }
    }

    return jsonify({
        "scenarios": scenarios,
        "users": {k: v["name"] for k, v in DEMO_USERS.items()}
    }), 200