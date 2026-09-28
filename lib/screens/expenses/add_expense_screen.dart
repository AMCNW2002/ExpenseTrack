// screens/expenses/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/category_icon.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expenseToEdit; // Edit කරන්න ඕන expense එක (optional)

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // ==========================================
  // CONTROLLERS & KEYS
  // ==========================================
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // ==========================================
  // STATE
  // ==========================================
  String _selectedCategory = AppConstants.categoryFood;
  DateTime _selectedDate = DateTime.now();
  bool _isEditMode = false;

  // ==========================================
  // INIT
  // ==========================================
  @override
  void initState() {
    super.initState();
    // Edit mode ද බලන්න
    if (widget.expenseToEdit != null) {
      _isEditMode = true;
      _titleController.text = widget.expenseToEdit!.title;
      _amountController.text = widget.expenseToEdit!.amount.toString();
      _noteController.text = widget.expenseToEdit!.note ?? '';
      _selectedCategory = widget.expenseToEdit!.category;
      _selectedDate = widget.expenseToEdit!.date;
    }
  }

  // ==========================================
  // DISPOSE
  // ==========================================
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ==========================================
  // DATE PICKER
  // ==========================================
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // ==========================================
  // SAVE EXPENSE
  // ==========================================
  Future<void> _handleSave() async {
    // Keyboard එක close කරන්න
    FocusScope.of(context).unfocus();

    // Form validation
    if (!_formKey.currentState!.validate()) return;

    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // Expense Model එක හදන්න
    ExpenseModel expense = ExpenseModel(
      id: widget.expenseToEdit?.id,
      userId: widget.expenseToEdit?.userId ?? '',
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.expenseToEdit?.createdAt,
    );

    // Save or Update
    bool success;
    if (_isEditMode) {
      success = await expenseProvider.updateExpense(expense);
    } else {
      success = await expenseProvider.addExpense(expense);
    }

    if (!mounted) return;

    if (success) {
      // Budget data refresh කරන්න
      await budgetProvider.recalculate();
      if (!mounted) return;

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _isEditMode
                    ? AppConstants.msgExpenseUpdated
                    : AppConstants.msgExpenseAdded,
              ),
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
      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  expenseProvider.errorMessage ?? 'Failed to save expense',
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

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Expense' : AppConstants.labelAddExpense,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ==========================================
                // TITLE FIELD
                // ==========================================
                CustomTextField(
                  label: 'What did you spend on?',
                  hint: 'e.g. Lunch, Bus ticket',
                  controller: _titleController,
                  prefixIcon: Icons.edit_outlined,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 2) {
                      return 'Title is too short';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==========================================
                // AMOUNT FIELD
                // ==========================================
                AmountTextField(
                  label: AppConstants.labelAmount,
                  hint: '0.00',
                  controller: _amountController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null) {
                      return 'Invalid amount';
                    }
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==========================================
                // CATEGORY SELECTOR
                // ==========================================
                const Text(
                  AppConstants.labelCategory,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Chips (සියලු category පෙන්නන්න)
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.expenseCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      String category = AppConstants.expenseCategories[index];
                      return CategoryChip(
                        category: category,
                        isSelected: _selectedCategory == category,
                        onTap: () {
                          setState(() => _selectedCategory = category);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // DATE PICKER
                // ==========================================
                DatePickerField(
                  label: AppConstants.labelDate,
                  selectedDate: _selectedDate,
                  onTap: _pickDate,
                ),

                const SizedBox(height: 20),

                // ==========================================
                // NOTE FIELD (Optional)
                // ==========================================
                CustomTextField(
                  label: '${AppConstants.labelNote} (optional)',
                  hint: 'Add a note...',
                  controller: _noteController,
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSave(),
                ),

                const SizedBox(height: 32),

                // ==========================================
                // SAVE BUTTON
                // ==========================================
                Consumer<ExpenseProvider>(
                  builder: (context, expenseProvider, _) {
                    return PrimaryButton(
                      text: _isEditMode
                          ? 'Update Expense'
                          : AppConstants.labelAddExpense,
                      onPressed: _handleSave,
                      isLoading: expenseProvider.isLoading,
                      icon: _isEditMode ? Icons.check : Icons.add,
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
