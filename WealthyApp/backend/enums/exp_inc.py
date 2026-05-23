import enum

class ExpenseIncome(str, enum.Enum):
    EXPENSE = "expense"
    INCOME = "income"