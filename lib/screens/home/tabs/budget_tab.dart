// screens/home/tabs/budget_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/finance_calculations.dart';

class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key});

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BudgetProvider>().refresh();
      }
    });
  }

  // ==========================================
  // FORMAT AMOUNT
  // ==========================================
  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '${AppConstants.currencySymbol} ${formatter.format(amount)}';
  }

  String _formatAmountShort(double amount) {
    final formatter = NumberFormat('#,##0');
    return '${AppConstants.currencySymbol} ${formatter.format(amount)}';
  }

  // ==========================================
  // EDIT TOTAL BUDGET DIALOG
  // ==========================================
  Future<void> _editTotalBudget(double currentBudget) async {
    final controller = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Set Monthly Budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your total monthly budget',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  prefixText: '${AppConstants.currencySymbol}  ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                  hintText: '0',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryPurple,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMedium,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final value = double.tryParse(controller.text.trim());
                      if (value != null && value > 0) {
                        Navigator.pop(dialogContext, value);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      final selectedMonth =
          Provider.of<BudgetProvider>(context, listen: false).selectedMonth;
      final previousMonth =
          DateTime(selectedMonth.year, selectedMonth.month - 1);
      final historicalExpenses = expenseProvider.getExpensesForLastMonths(
        months: 6,
        relativeTo: previousMonth,
      );
      final historicalSpending = calculateSpendingByCategory(
        historicalExpenses,
        categories: AppConstants.expenseCategories,
      );
      final suggestedAllocations = calculateBudgetAllocations(
        totalBudget: result,
        spendingByCategory: historicalSpending,
        categories: AppConstants.expenseCategories,
      );
      await _editBudgetAllocations(
        totalBudget: result,
        initialAllocations: suggestedAllocations,
      );
    }
  }

  Future<void> _editBudgetAllocations({
    required double totalBudget,
    required Map<String, double> initialAllocations,
  }) async {
    final allocations = await showDialog<Map<String, double>>(
      context: context,
      builder: (_) => _CategoryBudgetAllocationDialog(
        totalBudget: totalBudget,
        initialAllocations: initialAllocations,
      ),
    );

    if (allocations != null && mounted) {
      final budgetProvider = context.read<BudgetProvider>();
      final success = await budgetProvider.saveBudgetAllocation(
        totalBudget: totalBudget,
        categoryBudgets: allocations,
      );
      if (!mounted) return;
      _showBudgetMessage(
        success
            ? AppConstants.msgBudgetUpdated
            : budgetProvider.errorMessage ??
                'Could not update budget allocations',
        isError: !success,
      );
    }
  }

  void _showBudgetMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, budgetProvider, _) {
            final totalBudget = budgetProvider.totalBudget == 0
                ? AppConstants.defaultMonthlyBudget
                : budgetProvider.totalBudget;
            final totalSpent = budgetProvider.totalSpent;

            double percentage =
                totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
            percentage = percentage.clamp(0.0, 100.0);

            return RefreshIndicator(
              onRefresh: () async {
                budgetProvider.refresh();
              },
              color: AppColors.primaryPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ==========================================
                    // HEADER (Title + Month)
                    // ==========================================
                    _buildHeader(budgetProvider),

                    const SizedBox(height: 20),

                    if (budgetProvider.errorMessage != null)
                      _buildLoadError(budgetProvider),
                    if (budgetProvider.isLoading)
                      const LinearProgressIndicator(minHeight: 2),

                    // ==========================================
                    // TOTAL BUDGET CARD
                    // ==========================================
                    _buildTotalBudgetCard(
                      totalBudget: totalBudget,
                      totalSpent: totalSpent,
                      percentage: percentage,
                      onEdit: () => _editTotalBudget(totalBudget),
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // CATEGORY BUDGETS HEADER
                    // ==========================================
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Category Budgets',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: budgetProvider.isSaving
                              ? null
                              : () => _editBudgetAllocations(
                                    totalBudget: totalBudget,
                                    initialAllocations: {
                                      for (final category
                                          in AppConstants.expenseCategories)
                                        category: budgetProvider
                                            .getCategoryBudget(category),
                                    },
                                  ),
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Adjust split'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ==========================================
                    // CATEGORY BUDGET LIST
                    // ==========================================
                    ..._buildCategoryList(budgetProvider, totalBudget),

                    const SizedBox(height: 24),

                    // ==========================================
                    // SMART TIP
                    // ==========================================
                    _buildSmartTip(budgetProvider, totalBudget, totalSpent),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildHeader(BudgetProvider budgetProvider) {
    final selectedMonth = budgetProvider.selectedMonth;
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Budget',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Previous month',
          onPressed: () =>
              budgetProvider.setMonth(shiftMonth(selectedMonth, -1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM yyyy').format(selectedMonth),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: isCurrentMonth
              ? null
              : () => budgetProvider.setMonth(shiftMonth(selectedMonth, 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildLoadError(BudgetProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.cloud_off_outlined, color: AppColors.error),
        title: const Text('Budget data could not be refreshed'),
        trailing: IconButton(
          tooltip: 'Retry',
          onPressed: () {
            provider.clearError();
            provider.refresh();
          },
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  // ==========================================
  // TOTAL BUDGET CARD
  // ==========================================
  Widget _buildTotalBudgetCard({
    required double totalBudget,
    required double totalSpent,
    required double percentage,
    required VoidCallback onEdit,
  }) {
    final double remaining = totalBudget - totalSpent;
    final bool isOver = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Top Row: Total Budget + Edit icon
          Row(
            children: [
              const Expanded(
                child: Text(
                  AppConstants.labelTotalBudget,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Amount
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatAmount(totalBudget),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver
                    ? AppColors.error
                    : percentage >= 80
                        ? AppColors.warning
                        : AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Spent + Remaining
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOver
                            ? AppColors.error
                            : percentage >= 80
                                ? AppColors.warning
                                : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Spent ${_formatAmountShort(totalSpent)} (${percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isOver
                    ? 'Over by ${_formatAmountShort(remaining.abs())}'
                    : '${_formatAmountShort(remaining)} left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOver ? AppColors.error : AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CATEGORY LIST
  // ==========================================
  List<Widget> _buildCategoryList(
    BudgetProvider budgetProvider,
    double totalBudget,
  ) {
    final List<Widget> widgets = [];

    for (String category in AppConstants.expenseCategories) {
      double catBudget = budgetProvider.getCategoryBudget(category);
      double catSpent = budgetProvider.getCategorySpent(category);

      // Budget එකක් නැත්නම් (0.0), ඒත් list එකේ පෙන්නන්න
      if (catBudget == 0 && catSpent == 0) {
        // Budget එක set කරලා නැති categories පෙන්නන්නේ නැහැ
        // නමුත් spent එකක් තියෙනවා නම් පෙන්නන්න
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCategoryCard(
            category: category,
            budget: catBudget,
            spent: catSpent,
            allocationPercentage:
                totalBudget > 0 ? catBudget / totalBudget * 100 : 0,
            onTap: () => _editBudgetAllocations(
              totalBudget: totalBudget,
              initialAllocations: {
                for (final item in AppConstants.expenseCategories)
                  item: budgetProvider.getCategoryBudget(item),
              },
            ),
          ),
        ),
      );
    }

    // කිසිම category එකකට budget නැත්නම්, default message එකක් පෙන්නන්න
    if (widgets.isEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppColors.textLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No category budgets set',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add an expense or set category budgets',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  // ==========================================
  // CATEGORY CARD
  // ==========================================
  Widget _buildCategoryCard({
    required String category,
    required double budget,
    required double spent,
    required double allocationPercentage,
    required VoidCallback onTap,
  }) {
    final Color categoryColor = AppColors.getCategoryColor(category);
    final IconData categoryIcon =
        AppConstants.categoryIcons[category] ?? Icons.more_horiz;

    final percentage = calculateCategoryBudgetPercentage(budget, spent);
    final isOverBudget = isCategoryBudgetOverLimit(budget, spent);
    final isNearLimit = budget > 0 &&
        isNearBudgetLimit(
          budget,
          spent,
          AppConstants.budgetWarningThreshold,
        );
    final statusColor = isOverBudget
        ? AppColors.error
        : isNearLimit
            ? AppColors.warning
            : categoryColor;
    final remaining = calculateAvailableToSpend(budget, spent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverBudget || isNearLimit
                  ? statusColor.withValues(alpha: 0.3)
                  : AppColors.border,
              width: isOverBudget || isNearLimit ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Top Row: Icon + Name + Amount
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category name
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),

                  // Amount + Percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatAmountShort(spent)} / ${_formatAmountShort(budget)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isOverBudget
                              ? AppColors.error
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${allocationPercentage.toStringAsFixed(0)}% of total budget',
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (budget > 0) ...[
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isOverBudget
                        ? 'Over budget by ${_formatAmountShort(spent - budget)}'
                        : isNearLimit
                            ? 'Near limit · ${_formatAmountShort(remaining)} left'
                            : '${_formatAmountShort(remaining)} left',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SMART TIP
  // ==========================================
  Widget _buildSmartTip(
    BudgetProvider budgetProvider,
    double totalBudget,
    double totalSpent,
  ) {
    String tip = budgetProvider.smartTip;

    if (budgetProvider.totalBudget == 0) {
      final percentage = totalBudget > 0 ? totalSpent / totalBudget * 100 : 0.0;
      if (totalSpent > totalBudget) {
        tip = 'You have exceeded the default budget. Reduce spending.';
      } else if (percentage >= 90) {
        tip =
            'You have used ${percentage.toStringAsFixed(0)}% of the default budget. Be careful!';
      } else if (percentage >= 80) {
        tip =
            'You have used ${percentage.toStringAsFixed(0)}% of the default budget.';
      } else {
        tip = 'Set a monthly budget to track your spending';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.labelSmartTip,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetAllocationDialog extends StatefulWidget {
  final double totalBudget;
  final Map<String, double> initialAllocations;

  const _CategoryBudgetAllocationDialog({
    required this.totalBudget,
    required this.initialAllocations,
  });

  @override
  State<_CategoryBudgetAllocationDialog> createState() =>
      _CategoryBudgetAllocationDialogState();
}

class _CategoryBudgetAllocationDialogState
    extends State<_CategoryBudgetAllocationDialog> {
  late final Map<String, double> _shares;

  @override
  void initState() {
    super.initState();
    final categories = AppConstants.expenseCategories;
    final allocationTotal = categories.fold<double>(
      0,
      (sum, category) => sum + (widget.initialAllocations[category] ?? 0),
    );
    _shares = {
      for (final category in categories)
        category: allocationTotal > 0
            ? ((widget.initialAllocations[category] ?? 0) / allocationTotal)
                .clamp(0.0, 1.0)
            : 1 / categories.length,
    };
  }

  void _setShare(String category, double share) {
    setState(() {
      _shares.addAll(
        redistributeCategoryShares(
          categories: AppConstants.expenseCategories,
          currentShares: Map.of(_shares),
          adjustedCategory: category,
          share: share,
        ),
      );
    });
  }

  Map<String, double> get _amounts => calculateBudgetAllocations(
        totalBudget: widget.totalBudget,
        spendingByCategory: _shares,
        categories: AppConstants.expenseCategories,
      );

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.expenseCategories;
    return AlertDialog(
      title: const Text('Adjust category split'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = AppColors.getCategoryColor(category);
            final share = _shares[category]!.clamp(0.0, 1.0);
            final amount = _amounts[category] ?? 0;
            final icon =
                AppConstants.categoryIcons[category] ?? Icons.more_horiz;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${(share * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: share,
                        min: 0,
                        max: 1,
                        divisions: 100,
                        activeColor: color,
                        onChanged: (value) => _setShare(category, value),
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: Text(
                        '${AppConstants.currencySymbol} ${NumberFormat('#,##0').format(amount)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _amounts),
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Save split'),
        ),
      ],
    );
  }
}
