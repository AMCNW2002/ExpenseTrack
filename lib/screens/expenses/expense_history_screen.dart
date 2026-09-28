// screens/expenses/expense_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/custom_textfield.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  // ==========================================
  // CONTROLLERS & STATE
  // ==========================================
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Screen එකට ආවම, filters reset කරන්න
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExpenseProvider>().clearFilters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // OPEN ADD EXPENSE
  // ==========================================
  Future<void> _openAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (result == true && mounted) {
      context.read<BudgetProvider>().refresh();
    }
  }

  // ==========================================
  // OPEN EXPENSE DETAILS
  // ==========================================
  void _openExpenseDetails(ExpenseModel expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expense: expense),
      ),
    );
  }

  // ==========================================
  // GROUP EXPENSES BY DATE
  // ==========================================
  Map<String, List<ExpenseModel>> _groupByDate(List<ExpenseModel> expenses) {
    Map<String, List<ExpenseModel>> grouped = {};

    for (var expense in expenses) {
      String key = _getDateLabel(expense.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(expense);
    }

    return grouped;
  }

  // ==========================================
  // GET DATE LABEL (Today/Yesterday/Date)
  // ==========================================
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';

    return DateFormat('dd MMM yyyy').format(date);
  }

  // ==========================================
  // FORMAT AMOUNT
  // ==========================================
  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '${AppConstants.currencySymbol} ${formatter.format(amount)}';
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          // Search toggle button
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<ExpenseProvider>().setSearchQuery('');
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, expenseProvider, _) {
            final expenses = expenseProvider.filteredExpenses;
            final grouped = _groupByDate(expenses);

            return Column(
              children: [
                // ==========================================
                // SEARCH BAR (Conditional)
                // ==========================================
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: SearchTextField(
                      controller: _searchController,
                      hint: 'Search expenses...',
                      onChanged: (value) {
                        expenseProvider.setSearchQuery(value);
                        setState(() {}); // Clear button update කරන්න
                      },
                      showClearButton: _searchController.text.isNotEmpty,
                      onClear: () {
                        _searchController.clear();
                        expenseProvider.setSearchQuery('');
                        setState(() {});
                      },
                    ),
                  ),

                // ==========================================
                // MONTH SELECTOR
                // ==========================================
                _buildMonthSelector(expenseProvider),

                const SizedBox(height: 8),

                // ==========================================
                // CATEGORY FILTER CHIPS
                // ==========================================
                CategoryFilterRow(
                  categories: AppConstants.expenseCategories,
                  selectedCategory: expenseProvider.selectedCategory,
                  onCategorySelected: (category) {
                    expenseProvider.setCategoryFilter(category);
                  },
                  includeAll: true,
                ),

                const SizedBox(height: 16),

                // ==========================================
                // EXPENSE LIST (Grouped by date)
                // ==========================================
                Expanded(
                  child: expenseProvider.isLoading
                      ? _buildLoading()
                      : expenses.isNotEmpty
                          ? Column(
                              children: [
                                if (expenseProvider.streamErrorMessage != null)
                                  _buildCachedDataWarning(
                                    expenseProvider.streamErrorMessage!,
                                    expenseProvider.refresh,
                                  ),
                                Expanded(
                                  child: _buildGroupedList(
                                    grouped,
                                    expenseProvider,
                                  ),
                                ),
                              ],
                            )
                          : expenseProvider.streamErrorMessage != null
                              ? _buildErrorState(
                                  expenseProvider.streamErrorMessage!,
                                  expenseProvider.refresh,
                                )
                              : _buildEmptyState(),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _openAddExpense,
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.textWhite,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // ==========================================
  // MONTH SELECTOR
  // ==========================================
  Widget _buildMonthSelector(ExpenseProvider expenseProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.textMedium,
              ),
              onPressed: () {
                DateTime prevMonth = DateTime(
                  expenseProvider.selectedMonth.year,
                  expenseProvider.selectedMonth.month - 1,
                  1,
                );
                expenseProvider.setMonthFilter(prevMonth);
                setState(() {});
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(AppConstants.monthFormat)
                          .format(expenseProvider.selectedMonth),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: AppColors.textMedium,
              ),
              onPressed: () {
                DateTime nextMonth = DateTime(
                  expenseProvider.selectedMonth.year,
                  expenseProvider.selectedMonth.month + 1,
                  1,
                );
                // Future month එකට යන්න එපා
                if (nextMonth
                    .isBefore(DateTime.now().add(const Duration(days: 1)))) {
                  expenseProvider.setMonthFilter(nextMonth);
                  setState(() {});
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GROUPED LIST
  // ==========================================
  Widget _buildGroupedList(
    Map<String, List<ExpenseModel>> grouped,
    ExpenseProvider expenseProvider,
  ) {
    List<String> keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        String dateLabel = keys[index];
        List<ExpenseModel> expensesInGroup = grouped[dateLabel]!;

        // එක group එකේ total එක ගණනය කරන්න
        double groupTotal = expensesInGroup.fold(
          0.0,
          (sum, expense) => sum + expense.amount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    _formatAmount(groupTotal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Expenses in this group
            ...expensesInGroup.map((expense) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpenseCard(
                  expense: expense,
                  onTap: () => _openExpenseDetails(expense),
                  showDate: false, // Date header එකේ තියෙන නිසා
                ),
              );
            }),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ==========================================
  // LOADING STATE
  // ==========================================
  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ExpenseCardSkeleton(),
        );
      },
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 50,
                color: AppColors.primaryPurple.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing filters or add a new expense',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _openAddExpense,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedDataWarning(String message, VoidCallback onRetry) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing saved expenses. $message',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Retry sync',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }
}
