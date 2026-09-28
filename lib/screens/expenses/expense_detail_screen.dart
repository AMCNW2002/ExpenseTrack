// screens/expenses/expense_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  // ==========================================
  // FORMAT HELPERS
  // ==========================================
  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '${AppConstants.currencySymbol} ${formatter.format(amount)}';
  }

  String _formatFullDate(DateTime date) {
    return DateFormat(AppConstants.dateFormatFull).format(date);
  }

  // ==========================================
  // EDIT EXPENSE
  // ==========================================
  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(expenseToEdit: expense),
      ),
    );

    if (result == true && context.mounted) {
      // Edit කරාට පස්සේ, detail screen එකෙන් back යන්න
      Navigator.pop(context, true);
    }
  }

  // ==========================================
  // DELETE CONFIRMATION DIALOG
  // ==========================================
  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Expense?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
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
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);

      bool success = await expenseProvider.deleteExpense(expense.id!);

      if (!context.mounted) return;

      if (success) {
        // Budget data refresh කරන්න
        await budgetProvider.recalculate();
        if (!context.mounted) return;

        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(AppConstants.msgExpenseDeleted),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Back to previous screen
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expenseProvider.errorMessage ?? 'Failed to delete',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final Color categoryColor = AppColors.getCategoryColor(expense.category);
    final IconData categoryIcon =
        AppConstants.categoryIcons[expense.category] ?? Icons.more_horiz;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Expense Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // ==========================================
              // MAIN INFO CARD
              // ==========================================
              Container(
                padding: const EdgeInsets.all(24),
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
                    // Category Icon (Big)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      expense.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expense.category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount (Big)
                    Text(
                      _formatAmount(expense.amount),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // DETAILS SECTION
              // ==========================================
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    _buildDetailRow(
                      icon: Icons.attach_money,
                      label: AppConstants.labelAmount,
                      value: _formatAmount(expense.amount),
                    ),
                    const Divider(
                      height: 24,
                      color: AppColors.divider,
                    ),

                    // Category
                    _buildDetailRow(
                      icon: Icons.category_outlined,
                      label: AppConstants.labelCategory,
                      value: expense.category,
                      valueColor: categoryColor,
                    ),
                    const Divider(
                      height: 24,
                      color: AppColors.divider,
                    ),

                    // Date
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: AppConstants.labelDate,
                      value: _formatFullDate(expense.date),
                    ),
                    const Divider(
                      height: 24,
                      color: AppColors.divider,
                    ),

                    // Note (තියෙනවා නම් විතරයි)
                    if (expense.note != null && expense.note!.isNotEmpty) ...[
                      _buildDetailRow(
                        icon: Icons.notes_outlined,
                        label: AppConstants.labelNote,
                        value: expense.note!,
                        isMultiline: true,
                      ),
                      const Divider(
                        height: 24,
                        color: AppColors.divider,
                      ),
                    ],

                    // Created At
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Added on',
                      value: DateFormat('dd MMM yyyy, hh:mm a')
                          .format(expense.createdAt),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // EDIT BUTTON (Primary)
              // ==========================================
              PrimaryButton(
                text: AppConstants.labelEdit,
                onPressed: () => _handleEdit(context),
                icon: Icons.edit_outlined,
              ),

              const SizedBox(height: 12),

              // ==========================================
              // DELETE BUTTON (Danger)
              // ==========================================
              PrimaryButton(
                text: AppConstants.labelDelete,
                onPressed: () => _handleDelete(context),
                icon: Icons.delete_outline,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                textColor: AppColors.error,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DETAIL ROW WIDGET
  // ==========================================
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(width: 12),

        // Label
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
        ),

        // Value
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textDark,
              height: isMultiline ? 1.5 : 1.2,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // OPTIONS MENU (AppBar)
  // ==========================================
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Edit Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryPurple,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Edit Expense',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _handleEdit(context);
                  },
                ),

                // Delete Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete Expense',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _handleDelete(context);
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
