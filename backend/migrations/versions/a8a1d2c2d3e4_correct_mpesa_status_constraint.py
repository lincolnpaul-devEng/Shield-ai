"""Correct M-Pesa status check constraint

Revision ID: a8a1d2c2d3e4
Revises: 745c2f94b400
Create Date: 2025-11-24 14:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a8a1d2c2d3e4'
down_revision = '745c2f94b400'
branch_labels = None
depends_on = None


def upgrade():
    # Drop the faulty check constraint and create a new, correct one.
    # The table name is 'mpesa_transaction'
    with op.batch_alter_table('mpesa_transaction', schema=None) as batch_op:
        try:
            batch_op.drop_constraint('mpesa_status_check', type_='check')
        except Exception as e:
            # The constraint might not exist on all dev environments, so ignore errors on drop
            print(f"Could not drop constraint 'mpesa_status_check', it may not exist. Error: {e}")

        batch_op.create_check_constraint(
            'mpesa_status_check',
            "status IN ('pending', 'completed', 'failed', 'cancelled')"
        )


def downgrade():
    # Revert to the old, faulty check constraint.
    with op.batch_alter_table('mpesa_transaction', schema=None) as batch_op:
        batch_op.drop_constraint('mpesa_status_check', type_='check')
        batch_op.create_check_constraint(
            'mpesa_status_check',
            'status IN ("pending", "completed", "failed", "cancelled")'
        )
