"""
Database seeder for Shield AI demo data.
Creates 3 demo users with 30 days of realistic Kenyan M-Pesa transaction patterns.
"""

import random
from datetime import datetime, timedelta
from . import db
from .models import User, Transaction


def seed_database():
    """Seed the database with demo data."""
    print("Seeding database with demo data...")

    # Clear existing data
    Transaction.query.delete()
    User.query.delete()
    db.session.commit()

    # Create demo users
    users_data = [
        {
            'phone': '254712345678',
            'name': 'student_mary',
            'spending_limit': 2000.0,  # Student budget
            'daily_avg': 150.0,
            'transaction_freq': 'high',  # Frequent small transactions
        },
        {
            'phone': '254798765432',
            'name': 'business_david',
            'spending_limit': 25000.0,  # Business owner
            'daily_avg': 1500.0,
            'transaction_freq': 'medium',  # Regular business transactions
        },
        {
            'phone': '254711223344',
            'name': 'mama_mboga_sarah',
            'spending_limit': 5000.0,  # Market vendor
            'daily_avg': 800.0,
            'transaction_freq': 'high',  # Many small customer payments
        }
    ]

    users = []
    for user_data in users_data:
        user = User(
            phone=user_data['phone'],
            normal_spending_limit=user_data['spending_limit']
        )
        db.session.add(user)
        users.append((user, user_data))
        print(f"Created user: {user_data['name']} ({user_data['phone']})")

    db.session.commit()

    # Generate 30 days of transactions for each user
    base_date = datetime.utcnow() - timedelta(days=30)

    kenyan_recipients = [
        '254722000000', '254733111111', '254744222222', '254755333333',
        '254766444444', '254777555555', '254788666666', '254799777777',
        '254700888888', '254711999999', '254722111111', '254733222222'
    ]

    locations = [
        'Nairobi CBD', 'Westlands', 'Karen', 'Kilimani', 'Langata',
        'River Road Market', 'Luthuli Avenue', 'Tom Mboya Street',
        'Koinange Street', 'Westlands Mall', 'Sarit Centre', None
    ]

    for user, user_data in users:
        transactions_created = 0
        fraud_transactions = 0

        for day in range(30):
            current_date = base_date + timedelta(days=day)

            # Generate transactions based on user pattern
            if user_data['transaction_freq'] == 'high':
                num_transactions = random.randint(3, 8)
            elif user_data['transaction_freq'] == 'medium':
                num_transactions = random.randint(2, 5)
            else:
                num_transactions = random.randint(1, 3)

            for _ in range(num_transactions):
                # Generate realistic transaction time (business hours + some evening)
                hour = random.choices(
                    [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
                    weights=[2, 3, 4, 5, 5, 4, 3, 2, 1, 1, 1, 1]
                )[0]
                minute = random.randint(0, 59)

                transaction_time = current_date.replace(hour=hour, minute=minute)

                # Generate amount based on user profile
                if user_data['name'] == 'student_mary':
                    # Student: small amounts, occasional larger for emergencies
                    if random.random() < 0.9:
                        amount = round(random.uniform(50, 500), 2)
                    else:
                        amount = round(random.uniform(1000, 2000), 2)
                elif user_data['name'] == 'business_david':
                    # Business: varied amounts, some large transfers
                    if random.random() < 0.7:
                        amount = round(random.uniform(500, 5000), 2)
                    else:
                        amount = round(random.uniform(10000, 20000), 2)
                else:  # mama_mboga_sarah
                    # Vendor: many small amounts from customers
                    amount = round(random.uniform(20, 200), 2)

                # Select recipient
                recipient = random.choice(kenyan_recipients)

                # Add some fraudulent transactions (about 5% of total)
                is_fraud = False
                fraud_confidence = 0.0

                if random.random() < 0.05:  # 5% fraud rate
                    is_fraud = True
                    fraud_confidence = round(random.uniform(0.7, 0.95), 2)

                    # Make fraudulent transactions more suspicious
                    if random.random() < 0.5:
                        # Large amount anomaly
                        amount = amount * random.uniform(3, 10)
                    else:
                        # Unusual time (3 AM)
                        transaction_time = transaction_time.replace(hour=3, minute=random.randint(0, 59))

                # Create transaction
                transaction = Transaction(
                    user_id=user.id,
                    amount=amount,
                    recipient=recipient,
                    timestamp=transaction_time,
                    location=random.choice(locations),
                    is_fraudulent=is_fraud,
                    fraud_confidence=fraud_confidence
                )

                db.session.add(transaction)
                transactions_created += 1
                if is_fraud:
                    fraud_transactions += 1

        print(f"Created {transactions_created} transactions for {user_data['name']} ({fraud_transactions} fraudulent)")

    db.session.commit()
    print("Database seeding completed!")


def clear_database():
    """Clear all data from database."""
    print("Clearing database...")
    Transaction.query.delete()
    User.query.delete()
    db.session.commit()
    print("Database cleared!")


if __name__ == "__main__":
    from . import create_app

    app = create_app()
    with app.app_context():
        seed_database()