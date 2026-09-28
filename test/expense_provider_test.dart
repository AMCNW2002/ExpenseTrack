import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/models/expense_model.dart';
import 'package:spendly/models/goal_model.dart';
import 'package:spendly/utils/finance_calculations.dart';

void main() {
  final expenses = [
    ExpenseModel(
      id: 'lunch',
      userId: 'user',
      title: 'Lunch',
      amount: 850,
      category: 'Food',
      date: DateTime(2026, 9, 3),
      note: 'Office meal',
    ),
    ExpenseModel(
      id: 'bus',
      userId: 'user',
      title: 'Bus ticket',
      amount: 300,
      category: 'Transport',
      date: DateTime(2026, 9, 8),
      note: 'Office commute',
    ),
    ExpenseModel(
      id: 'groceries',
      userId: 'user',
      title: 'Groceries',
      amount: 2500,
      category: 'Food',
      date: DateTime(2026, 8, 29),
    ),
    ExpenseModel(
      id: 'books',
      userId: 'user',
      title: 'Books',
      amount: 700,
      category: 'Education',
      date: DateTime(2026, 5, 12),
    ),
    ExpenseModel(
      id: 'old',
      userId: 'user',
      title: 'Old expense',
      amount: 500,
      category: 'Other',
      date: DateTime(2026, 3, 31),
    ),
    ExpenseModel(
      id: 'future',
      userId: 'user',
      title: 'Future expense',
      amount: 900,
      category: 'Other',
      date: DateTime(2026, 10, 1),
    ),
  ];

  group('filterExpenses', () {
    test('filters expenses to the selected month', () {
      final result = filterExpenses(
        expenses: expenses,
        month: DateTime(2026, 9),
        category: 'All',
        searchQuery: '',
      );

      expect(result.map((expense) => expense.id), ['lunch', 'bus']);
    });

    test('combines month, category, and note search filters', () {
      final result = filterExpenses(
        expenses: expenses,
        month: DateTime(2026, 9),
        category: 'Food',
        searchQuery: 'OFFICE',
      );

      expect(result.map((expense) => expense.id), ['lunch']);
    });

    test('matches category and title search without case sensitivity', () {
      final result = filterExpenses(
        expenses: expenses,
        month: DateTime(2026, 9),
        category: 'food',
        searchQuery: 'lUnCh',
      );

      expect(result.map((expense) => expense.id), ['lunch']);
    });
  });

  group('expense totals', () {
    test('calculates all-time and selected-month totals', () {
      expect(totalExpenseAmount(expenses), 5750);
      expect(
        totalExpenseAmount(expensesForMonth(expenses, DateTime(2026, 9))),
        1150,
      );
    });

    test('aggregates selected-month spending by category', () {
      final result = calculateSpendingByCategory(
        expensesForMonth(expenses, DateTime(2026, 9)),
        categories: ['Food', 'Transport', 'Bills'],
      );

      expect(result, {
        'Food': 850,
        'Transport': 300,
        'Bills': 0,
      });
    });

    test('uses the same exact 1, 3, and 6 month windows for charts and totals',
        () {
      final referenceDate = DateTime(2026, 9, 28);
      final oneMonth = expensesForLastMonths(
        expenses,
        months: 1,
        relativeTo: referenceDate,
      );
      final threeMonths = expensesForLastMonths(
        expenses,
        months: 3,
        relativeTo: referenceDate,
      );
      final sixMonths = expensesForLastMonths(
        expenses,
        months: 6,
        relativeTo: referenceDate,
      );
      final threeMonthTrend = monthlyExpenseTotals(
        expenses,
        months: 3,
        relativeTo: referenceDate,
      );
      final sixMonthTrend = monthlyExpenseTotals(
        expenses,
        months: 6,
        relativeTo: referenceDate,
      );
      final threeMonthCategories = calculateSpendingByCategory(threeMonths);

      expect(oneMonth.map((expense) => expense.id), ['lunch', 'bus']);
      expect(threeMonths.map((expense) => expense.id), [
        'lunch',
        'bus',
        'groceries',
      ]);
      expect(sixMonths.map((expense) => expense.id), [
        'lunch',
        'bus',
        'groceries',
        'books',
      ]);
      expect(threeMonthTrend.keys, ['7/26', '8/26', '9/26']);
      expect(sixMonthTrend.keys, [
        '4/26',
        '5/26',
        '6/26',
        '7/26',
        '8/26',
        '9/26',
      ]);
      expect(totalExpenseAmount(oneMonth), 1150);
      expect(totalExpenseAmount(threeMonths), 3650);
      expect(totalExpenseAmount(sixMonths), 4350);
      expect(threeMonthCategories['Food'], 3350);
      expect(threeMonthCategories['Transport'], 300);
      expect(
        threeMonthTrend.values.fold<double>(0, (sum, value) => sum + value),
        totalExpenseAmount(threeMonths),
      );
    });
  });

  group('budget calculations', () {
    test('allocates a total budget by historical category spending', () {
      final allocations = calculateBudgetAllocations(
        totalBudget: 1000,
        spendingByCategory: {'Food': 300, 'Transport': 100, 'Bills': 0},
        categories: ['Food', 'Transport', 'Bills'],
      );

      expect(allocations, {'Food': 750, 'Transport': 250, 'Bills': 0});
    });

    test('splits evenly without history and preserves every cent', () {
      final allocations = calculateBudgetAllocations(
        totalBudget: 100.01,
        spendingByCategory: {},
        categories: ['Food', 'Transport', 'Bills'],
      );

      expect(allocations.values.fold<double>(0, (sum, value) => sum + value),
          100.01);
      expect(allocations.values.toList(), [33.34, 33.34, 33.33]);
    });

    test('ignores invalid historical amounts and handles empty categories', () {
      expect(
        calculateBudgetAllocations(
          totalBudget: 100,
          spendingByCategory: {'Food': double.nan, 'Bills': -20},
          categories: ['Food', 'Bills'],
        ),
        {'Food': 50, 'Bills': 50},
      );
      expect(
        calculateBudgetAllocations(
          totalBudget: 100,
          spendingByCategory: {},
          categories: [],
        ),
        isEmpty,
      );
    });

    test('changing one category share redistributes the remainder to 100%', () {
      final shares = redistributeCategoryShares(
        categories: ['Food', 'Transport', 'Bills'],
        currentShares: {'Food': 0.5, 'Transport': 0.3, 'Bills': 0.2},
        adjustedCategory: 'Food',
        share: 0.7,
      );

      expect(shares['Food'], 0.7);
      expect(shares['Transport'], closeTo(0.18, 0.0001));
      expect(shares['Bills'], closeTo(0.12, 0.0001));
      expect(shares.values.reduce((sum, value) => sum + value), 1);
    });

    test('redistributes evenly when other categories have no share', () {
      final shares = redistributeCategoryShares(
        categories: ['Food', 'Transport', 'Bills'],
        currentShares: {'Food': 1, 'Transport': 0, 'Bills': 0},
        adjustedCategory: 'Food',
        share: 0.4,
      );

      expect(shares['Food'], 0.4);
      expect(shares['Transport'], closeTo(0.3, 0.0001));
      expect(shares['Bills'], closeTo(0.3, 0.0001));
      expect(shares.values.reduce((sum, value) => sum + value), 1);
    });

    test('moves between months across year boundaries', () {
      expect(shiftMonth(DateTime(2026, 1, 28), -1), DateTime(2025, 12));
      expect(shiftMonth(DateTime(2025, 12, 12), 1), DateTime(2026, 1));
    });

    test('calculates available amount, percentage, and warning threshold', () {
      expect(calculateAvailableToSpend(10000, 8000), 2000);
      expect(calculateBudgetPercentage(10000, 8000), 80);
      expect(isNearBudgetLimit(10000, 8000, 0.8), isTrue);
      expect(isNearBudgetLimit(10000, 7999, 0.8), isFalse);
      expect(isNearBudgetLimit(1000, 850, 0.8), isTrue);
      expect(isNearBudgetLimit(1000, 799, 0.8), isFalse);
    });

    test('caps over-budget percentage and available amount', () {
      expect(calculateAvailableToSpend(10000, 12500), 0);
      expect(calculateBudgetPercentage(10000, 12500), 100);
      expect(isBudgetOverLimit(10000, 12500), isTrue);
    });

    test('handles zero budgets and category limits', () {
      expect(calculateBudgetPercentage(0, 50), 0);
      expect(calculateCategoryBudgetPercentage(1000, 850), 85);
      expect(calculateCategoryBudgetPercentage(1000, 1200), 100);
      expect(isCategoryBudgetOverLimit(1000, 1200), isTrue);
      expect(isCategoryBudgetOverLimit(0, 1200), isFalse);
    });
  });

  group('savings goal progress', () {
    test('calculates progress, completion, and remaining amount', () {
      final goal = GoalModel(
        userId: 'user',
        title: 'Headphones',
        targetAmount: 30000,
        savedAmount: 18500,
      );

      expect(goal.progress, closeTo(18500 / 30000, 0.0001));
      expect(goal.progressPercentage, 62);
      expect(goal.remainingAmount, 11500);
      expect(goal.isCompleted, isFalse);
    });

    test('caps completed progress and handles a zero target', () {
      final completedGoal = GoalModel(
        userId: 'user',
        title: 'Completed',
        targetAmount: 100,
        savedAmount: 150,
      );
      final zeroTargetGoal = GoalModel(
        userId: 'user',
        title: 'No target',
        targetAmount: 0,
      );

      expect(completedGoal.progress, 1);
      expect(completedGoal.remainingAmount, 0);
      expect(completedGoal.isCompleted, isTrue);
      expect(zeroTargetGoal.progress, 0);
    });
  });
}
