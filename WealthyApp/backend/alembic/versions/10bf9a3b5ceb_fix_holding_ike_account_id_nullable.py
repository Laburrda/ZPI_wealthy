"""fix_holding_ike_account_id_nullable

Revision ID: 10bf9a3b5ceb
Revises: fb07a55d60fe
Create Date: 2026-05-24 20:19:06.685557

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '10bf9a3b5ceb'
down_revision: Union[str, None] = 'fb07a55d60fe'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('holdings') as batch_op:
        batch_op.alter_column(
            'ike_account_id',
            existing_type=sa.INTEGER(),
            nullable=True,
        )


def downgrade() -> None:
    with op.batch_alter_table('holdings') as batch_op:
        batch_op.alter_column(
            'ike_account_id',
            existing_type=sa.INTEGER(),
            nullable=False,
        )
    # ### end Alembic commands ###
