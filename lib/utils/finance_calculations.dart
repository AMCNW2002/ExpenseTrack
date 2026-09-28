import '../models/expense_model.dart';

DateTime shiftMonth(DateTime month, int offset) {
  return DateTime(month.year, month.month + offset, 1);
}

List<ExpenseModel> expensesForMonth(
  Iterable<ExpenseModel> expenses,
  DateTime month,
) {
  return expenses.where((expense) {
    return expense.date.year == month.year && expense.date.month == month.month;
  }).toList();
}

List<ExpenseModel> expensesForLastMonths(
  Iterable<ExpenseModel> expenses, {
  required int months,
  DateTime? relativeTo,
}) {
  if (months <= 0) return [];

  final current = relativeTo ?? DateTime.now();
  final start = DateTime(current.year, current.month - months + 1);
  final end = DateTime(current.year, current.month + 1);

  return expenses.where((expense) {
    return !expense.date.isBefore(start) && expense.date.isBefore(end);
  }).toList();
}

Map<String, double> monthlyExpenseTotals(
  Iterable<ExpenseModel> expenses, {
  required int months,
  DateTime? relativeTo,
}) {
  if (months <= 0) return {};

  final current = relativeTo ?? DateTime.now();
  final periodExpenses = expensesForLastMonths(
    expenses,
    months: months,
    relativeTo: current,
  );
  final totals = <String, double>{};

  for (var offset = months - 1; offset >= 0; offset--) {
    final month = DateTime(current.year, current.month - offset);
    final key = '${month.month}/${month.year.toString().substring(2)}';
    totals[key] = totalExpenseAmount(expensesForMonth(periodExpenses, month));
  }

  return totals;
}

List<ExpenseModel> filterExpenses({
  required Iterable<ExpenseModel> expenses,
  required DateTime month,
  required String category,
  required String searchQuery,
}) {
  final query = searchQuery.trim().toLowerCase();

  return expenses.where((expense) {
    final matchesMonth =
        expense.date.year == month.year && expense.date.month == month.month;
    final matchesCategory = category == 'All' ||
        expense.category.toLowerCase() == category.toLowerCase();
    final matchesQuery = query.isEmpty ||
        expense.title.toLowerCase().contains(query) ||
        expense.category.toLowerCase().contains(query) ||
        (expense.note?.toLowerCase().contains(query) ?? false);

    return matchesMonth && matchesCategory && matchesQuery;
  }).toList();
}

double totalExpenseAmount(Iterable<ExpenseModel> expenses) {
  return expenses.fold(0.0, (total, expense) => total + expense.amount);
}

Map<String, double> calculateSpendingByCategory(
  Iterable<ExpenseModel> expenses, {
  Iterable<String> categories = const [],
}) {
  final totals = {for (final category in categories) category: 0.0};

  for (final expense in expenses) {
    totals[expense.category] =
        (totals[expense.category] ?? 0.0) + expense.amount;
  }

  return totals;
}

Map<String, double> calculateBudgetAllocations({
  required double totalBudget,
  required Map<String, double> spendingByCategory,
  required List<String> categories,
}) {
  if (categories.isEmpty) return {};

  final totalCents =
      totalBudget.isFinite && totalBudget > 0 ? (totalBudget * 100).round() : 0;
  final weights = categories.map((category) {
    final spending = spendingByCategory[category] ?? 0;
    return spending.isFinite && spending > 0 ? spending : 0.0;
  }).toList();
  final totalWeight = weights.fold<double>(0, (sum, weight) => sum + weight);
  final effectiveWeights =
      totalWeight > 0 ? weights : List<double>.filled(categories.length, 1);
  final effectiveTotal = totalWeight > 0 ? totalWeight : categories.length;
  final exactCents = effectiveWeights
      .map((weight) => totalCents * weight / effectiveTotal)
      .toList();
  final allocatedCents = exactCents.map((value) => value.floor()).toList();
  var remainingCents =
      totalCents - allocatedCents.fold<int>(0, (sum, amount) => sum + amount);
  final remainderOrder = List<int>.generate(categories.length, (index) => index)
    ..sort((first, second) {
      final fractionDifference =
          (exactCents[second] - exactCents[second].floor()) -
              (exactCents[first] - exactCents[first].floor());
      return fractionDifference == 0
          ? first.compareTo(second)
          : fractionDifference > 0
              ? 1
              : -1;
    });

  for (var index = 0; remainingCents > 0; index++, remainingCents--) {
    allocatedCents[remainderOrder[index % remainderOrder.length]]++;
  }

  return {
    for (var index = 0; index < categories.length; index++)
      categories[index]: allocatedCents[index] / 100,
  };
}

Map<String, double> redistributeCategoryShares({
  required List<String> categories,
  required Map<String, double> currentShares,
  required String adjustedCategory,
  required double share,
}) {
  if (categories.isEmpty) return {};

  final selectedShare = share.isFinite ? share.clamp(0.0, 1.0) : 0.0;
  final others = categories.where((category) => category != adjustedCategory);
  if (!categories.contains(adjustedCategory) || others.isEmpty) {
    final equalShare = 1 / categories.length;
    return {for (final category in categories) category: equalShare};
  }

  final otherCategories = others.toList();
  final otherTotal = otherCategories.fold<double>(0, (sum, category) {
    final value = currentShares[category] ?? 0;
    return sum + (value.isFinite && value > 0 ? value : 0);
  });
  final remainingShare = 1 - selectedShare;
  var assignedShare = 0.0;
  final result = <String, double>{adjustedCategory: selectedShare};

  for (var index = 0; index < otherCategories.length; index++) {
    final category = otherCategories[index];
    final currentShare = currentShares[category] ?? 0;
    final nextShare = index == otherCategories.length - 1
        ? remainingShare - assignedShare
        : otherTotal > 0 && currentShare.isFinite && currentShare > 0
            ? remainingShare * currentShare / otherTotal
            : remainingShare / otherCategories.length;
    result[category] = nextShare;
    assignedShare += nextShare;
  }

  return {for (final category in categories) category: result[category] ?? 0};
}

double calculateAvailableToSpend(double budget, double spent) {
  final available = budget - spent;
  return available > 0 ? available : 0.0;
}

double calculateBudgetPercentage(double budget, double spent) {
  if (budget <= 0) return 0.0;
  return ((spent / budget) * 100).clamp(0.0, 100.0);
}

bool isBudgetOverLimit(double budget, double spent) => spent > budget;

bool isNearBudgetLimit(double budget, double spent, double threshold) {
  return calculateBudgetPercentage(budget, spent) >= threshold * 100;
}

double calculateCategoryBudgetPercentage(double budget, double spent) {
  return calculateBudgetPercentage(budget, spent);
}

bool isCategoryBudgetOverLimit(double budget, double spent) {
  return budget > 0 && spent > budget;
}
