from flask import Blueprint, jsonify, request, current_app
from datetime import datetime
from .. import db
from ..models import User, Transaction, UserBudgetPlan
from ..fraud_detector import FraudDetector
from ..financial_strategist import FinancialStrategist

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
            db.session.rollback()
            current_app.logger.error(f"Database error saving transaction: {db_error}")
            # Still return fraud result even if save fails
            fraud_result['warning'] = 'Transaction detected but not saved to database'

        return jsonify(fraud_result), 200

    except Exception as e:
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

        db.session.add(user)
        db.session.commit()

        return jsonify(user.to_dict()), 201

    except Exception as e:
        current_app.logger.exception("Error in /users")
        db.session.rollback()
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/users/<string:user_id>/balance", methods=["POST"])
def update_balance(user_id: str):
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        balance = payload.get('balance')
        pin = payload.get('pin')

        if balance is None or pin is None:
            return jsonify({"error": "bad_request", "message": "Balance and PIN are required"}), 400

        try:
            balance = float(balance)
            if balance < 0:
                return jsonify({"error": "bad_request", "message": "Balance cannot be negative"}), 400
        except (TypeError, ValueError):
            return jsonify({"error": "bad_request", "message": "Invalid balance format"}), 400

        # Find user by phone number
        user = User.query.filter_by(phone=user_id).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Verify PIN
        if not user.check_pin(pin):
            return jsonify({"error": "unauthorized", "message": "Invalid PIN"}), 401

        # Update balance
        user.mpesa_balance = balance
        db.session.commit()

        return jsonify({
            "message": "Balance updated successfully",
            "balance": float(user.mpesa_balance)
        }), 200

    except Exception as e:
        current_app.logger.exception("Error in /users/<user_id>/balance")
        db.session.rollback()
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/ask-ai", methods=["POST"])
def ask_ai():
    """Ask AI a question about financial planning"""
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        user_id = payload.get('user_id')
        question = payload.get('question')

        if not user_id or not question:
            return jsonify({"error": "bad_request", "message": "Missing user_id or question"}), 400

        # Get user (PIN validation removed for AI conversations - user should be authenticated)
        user = User.query.filter_by(phone=user_id).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Get user's current plan data (simplified for now)
        plan_data = {
            'weekly_budget': 2500,
            'monthly_budget': 10000,
            'financial_health_score': 75,
            'categories': [
                {'name': 'Food', 'allocated': 1500},
                {'name': 'Transport', 'allocated': 800},
                {'name': 'Airtime', 'allocated': 500},
            ]
        }

        # Ask AI the question
        strategist = FinancialStrategist()
        answer = strategist.ask_question(question, user.id, plan_data)

        return jsonify({
            "question": question,
            "answer": answer,
            "timestamp": datetime.utcnow().isoformat()
        }), 200

    except Exception as e:
        current_app.logger.exception("Error in /ask-ai")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/users/<string:user_id>/budget-plans", methods=["GET"])
def get_user_budget_plans(user_id: str):
    """Get all budget plans for a user"""
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

        # Get all plans for user
        plans = UserBudgetPlan.get_all_plans_for_user(user.id)
        plan_data = [plan.to_dict() for plan in plans]

        return jsonify({"plans": plan_data}), 200

    except Exception as e:
        current_app.logger.exception("Error in /users/<user_id>/budget-plans")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/users/<string:user_id>/budget-plans", methods=["POST"])
def create_user_budget_plan(user_id: str):
    """Create a new budget plan for a user"""
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        pin = payload.get('pin')
        plan_name = payload.get('plan_name')
        monthly_income = payload.get('monthly_income')
        allocations = payload.get('allocations')

        if not pin or not plan_name or monthly_income is None or not allocations:
            return jsonify({"error": "bad_request", "message": "PIN, plan_name, monthly_income, and allocations are required"}), 400

        # Find user by phone number
        user = User.query.filter_by(phone=user_id).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Verify PIN
        if not user.check_pin(pin):
            return jsonify({"error": "unauthorized", "message": "Invalid PIN"}), 401

        # Check if plan name already exists for this user
        existing_plan = UserBudgetPlan.query.filter_by(user_id=user.id, plan_name=plan_name).first()
        if existing_plan:
            return jsonify({"error": "conflict", "message": "A budget plan with this name already exists"}), 409

        # Validate allocations
        try:
            monthly_income = float(monthly_income)
            if monthly_income <= 0:
                return jsonify({"error": "bad_request", "message": "Monthly income must be positive"}), 400

            total_allocated = sum(float(amount) for amount in allocations.values())
            if total_allocated > monthly_income:
                return jsonify({"error": "bad_request", "message": "Total allocations cannot exceed monthly income"}), 400
        except (TypeError, ValueError):
            return jsonify({"error": "bad_request", "message": "Invalid income or allocation format"}), 400

        # Generate unique plan ID
        import uuid
        plan_id = str(uuid.uuid4())

        # Create new budget plan
        plan = UserBudgetPlan(
            id=plan_id,
            user_id=user.id,
            plan_name=plan_name,
            plan_description=payload.get('plan_description'),
            monthly_income=monthly_income,
            savings_goal=payload.get('savings_goal'),
            savings_period_months=payload.get('savings_period_months'),
            allocations=allocations,
            is_active=payload.get('is_active', True)
        )

        db.session.add(plan)
        db.session.commit()

        return jsonify(plan.to_dict()), 201

    except Exception as e:
        current_app.logger.exception("Error in POST /users/<user_id>/budget-plans")
        db.session.rollback()
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/users/<string:user_id>/budget-plans/<string:plan_id>", methods=["PUT"])
def update_user_budget_plan(user_id: str, plan_id: str):
    """Update an existing budget plan"""
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        pin = payload.get('pin')
        if not pin:
            return jsonify({"error": "bad_request", "message": "PIN is required"}), 400

        # Find user by phone number
        user = User.query.filter_by(phone=user_id).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Verify PIN
        if not user.check_pin(pin):
            return jsonify({"error": "unauthorized", "message": "Invalid PIN"}), 401

        # Find the plan
        plan = UserBudgetPlan.query.filter_by(id=plan_id, user_id=user.id).first()
        if not plan:
            return jsonify({"error": "not_found", "message": "Budget plan not found"}), 404

        # Update plan fields
        if 'plan_name' in payload:
            plan.plan_name = payload['plan_name']
        if 'plan_description' in payload:
            plan.plan_description = payload['plan_description']
        if 'monthly_income' in payload:
            try:
                monthly_income = float(payload['monthly_income'])
                if monthly_income <= 0:
                    return jsonify({"error": "bad_request", "message": "Monthly income must be positive"}), 400
                plan.monthly_income = monthly_income
            except (TypeError, ValueError):
                return jsonify({"error": "bad_request", "message": "Invalid income format"}), 400
        if 'savings_goal' in payload:
            plan.savings_goal = payload['savings_goal']
        if 'savings_period_months' in payload:
            plan.savings_period_months = payload['savings_period_months']
        if 'allocations' in payload:
            allocations = payload['allocations']
            try:
                total_allocated = sum(float(amount) for amount in allocations.values())
                if total_allocated > plan.monthly_income:
                    return jsonify({"error": "bad_request", "message": "Total allocations cannot exceed monthly income"}), 400
                plan.allocations = allocations
            except (TypeError, ValueError):
                return jsonify({"error": "bad_request", "message": "Invalid allocation format"}), 400
        if 'is_active' in payload:
            plan.is_active = bool(payload['is_active'])

        db.session.commit()

        return jsonify(plan.to_dict()), 200

    except Exception as e:
        current_app.logger.exception("Error in PUT /users/<user_id>/budget-plans/<plan_id>")
        db.session.rollback()
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/users/<string:user_id>/budget-plans/<string:plan_id>", methods=["DELETE"])
def delete_user_budget_plan(user_id: str, plan_id: str):
    """Delete a budget plan"""
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

        # Find and delete the plan
        plan = UserBudgetPlan.query.filter_by(id=plan_id, user_id=user.id).first()
        if not plan:
            return jsonify({"error": "not_found", "message": "Budget plan not found"}), 404

        db.session.delete(plan)
        db.session.commit()

        return jsonify({"message": "Budget plan deleted successfully"}), 200

    except Exception as e:
        current_app.logger.exception("Error in DELETE /users/<user_id>/budget-plans/<plan_id>")
        db.session.rollback()
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/budget-templates", methods=["GET"])
def get_budget_templates():
    """Get predefined budget templates"""
    try:
        templates = [
            {
                "id": "50-30-20",
                "name": "50/30/20 Rule",
                "description": "50% needs, 30% wants, 20% savings",
                "allocations": {
                    "needs": 0.5,  # Percentage of income
                    "wants": 0.3,
                    "savings": 0.2
                }
            },
            {
                "id": "70-20-10",
                "name": "70/20/10 Rule",
                "description": "70% essentials, 20% savings, 10% investments",
                "allocations": {
                    "essentials": 0.7,
                    "savings": 0.2,
                    "investments": 0.1
                }
            },
            {
                "id": "60-20-20",
                "name": "60/20/20 Rule",
                "description": "60% living expenses, 20% savings, 20% debt repayment",
                "allocations": {
                    "living_expenses": 0.6,
                    "savings": 0.2,
                    "debt_repayment": 0.2
                }
            }
        ]

        return jsonify({"templates": templates}), 200

    except Exception as e:
        current_app.logger.exception("Error in /budget-templates")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500


@api_bp.route("/mpesa-max", methods=["POST"])
def ask_mpesa_max():
    """Get financial advice from M-Pesa Max AI assistant"""
    try:
        payload = request.get_json(silent=True) or {}

        # Validate required fields
        user_id = payload.get('user_id')
        user_query = payload.get('query')

        if not user_id or not user_query:
            return jsonify({"error": "bad_request", "message": "Missing user_id or query"}), 400

        # Get user (PIN validation removed for AI conversations - user should be authenticated)
        user = User.query.filter_by(phone=user_id).first()
        if not user:
            return jsonify({"error": "not_found", "message": "User not found"}), 404

        # Build user context for personalized responses
        user_context = {}

        # Include user's M-Pesa balance
        user_context['mpesa_balance'] = float(user.mpesa_balance) if user.mpesa_balance is not None else 0.0

        # Include conversation history if provided
        conversation_history = payload.get('conversation_history', [])
        if conversation_history:
            # Format conversation history for context
            formatted_history = []
            for msg in conversation_history[-10:]:  # Last 10 messages for context
                formatted_history.append({
                    'role': 'user' if msg.get('is_from_user', msg.get('isFromUser')) else 'assistant',
                    'content': msg.get('question', msg.get('content', '')) if msg.get('is_from_user', msg.get('isFromUser')) else msg.get('answer', msg.get('content', '')),
                    'timestamp': msg.get('timestamp', '')
                })
            user_context['conversation_history'] = formatted_history

        # Get recent transactions for context
        recent_transactions = Transaction.query.filter_by(user_id=user.id)\
            .order_by(Transaction.timestamp.desc())\
            .limit(10)\
            .all()
        if recent_transactions:
            user_context['recent_transactions'] = [tx.to_dict() for tx in recent_transactions]

        # Get user's active budget plan
        active_plan = UserBudgetPlan.query.filter_by(user_id=user.id, is_active=True).first()
        if active_plan:
            user_context['budget_info'] = active_plan.to_dict()

        # Get spending patterns (last 30 days)
        from datetime import timedelta
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)

        spending_query = db.session.query(
            Transaction.recipient,
            db.func.sum(Transaction.amount).label('total_spent')
        ).filter(
            Transaction.user_id == user.id,
            Transaction.amount > 0,  # Only outgoing transactions
            Transaction.timestamp >= thirty_days_ago
        ).group_by(Transaction.recipient)\
         .order_by(db.desc('total_spent'))\
         .limit(5)\
         .all()

        if spending_query:
            spending_patterns = [
                {'recipient': row[0], 'amount': float(row[1])}
                for row in spending_query
            ]
            user_context['spending_patterns'] = spending_patterns

        # Get M-Pesa Max response
        detector = FraudDetector()
        max_response = detector.get_mpesa_max_response(user_query, user_context)

        return jsonify({
            "question": user_query,
            "answer": max_response.get('response', 'Unable to generate response'),
            "model_used": max_response.get('model_used', 'unknown'),
            "timestamp": datetime.utcnow().isoformat(),
            "context_used": bool(user_context)
        }), 200

    except Exception as e:
        current_app.logger.exception("Error in /mpesa-max")
        return jsonify({"error": "internal_server_error", "message": "An unexpected error occurred"}), 500
