import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GoalProvider>().refresh();
    });
  }

  String _formatAmount(double amount) {
    return '${AppConstants.currencySymbol} ${NumberFormat('#,##0.##').format(amount)}';
  }

  Future<void> _openGoalForm({GoalModel? goal}) async {
    if (context.read<GoalProvider>().isSaving) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalFormSheet(goal: goal),
    );
    if (saved == true && mounted) {
      _showMessage(goal == null ? 'Savings goal created' : 'Goal updated');
    }
  }

  Future<void> _addSavings(GoalModel goal) async {
    if (goal.id == null || context.read<GoalProvider>().isSaving) return;
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _AddSavingsDialog(
        goalTitle: goal.title,
        remainingAmount: goal.remainingAmount,
        remainingAmountLabel: _formatAmount(goal.remainingAmount),
      ),
    );

    if (amount == null || !mounted) return;
    final provider = context.read<GoalProvider>();
    final success = await provider.addToGoal(goal.id!, amount);
    if (!mounted) return;
    _showMessage(
      success
          ? 'Savings added to ${goal.title}'
          : provider.errorMessage ?? 'Could not update goal',
      isError: !success,
    );
  }

  Future<void> _deleteGoal(GoalModel goal) async {
    if (goal.id == null || context.read<GoalProvider>().isSaving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete savings goal?'),
        content: Text('Delete "${goal.title}" and its saved progress?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<GoalProvider>();
    final success = await provider.deleteGoal(goal.id!);
    if (!mounted) return;
    _showMessage(
      success
          ? 'Savings goal deleted'
          : provider.errorMessage ?? 'Could not delete goal',
      isError: !success,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Savings goals'),
        actions: [
          IconButton(
            tooltip: 'Create goal',
            onPressed: () => _openGoalForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GoalProvider>(
          builder: (context, provider, _) {
            final goals = _showCompleted
                ? provider.completedGoals
                : provider.goalsByProgress;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _buildSummary(provider),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Active (${provider.activeGoalsCount})'),
                      icon: const Icon(Icons.flag_outlined),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label:
                          Text('Completed (${provider.completedGoalsCount})'),
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {_showCompleted},
                  onSelectionChanged: (selection) {
                    setState(() => _showCompleted = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null &&
                    provider.goals.isEmpty)
                  _buildErrorState(provider)
                else if (goals.isEmpty)
                  _buildEmptyState()
                else ...[
                  if (provider.errorMessage != null) ...[
                    _buildErrorBanner(provider),
                    const SizedBox(height: 12),
                  ],
                  for (final goal in goals) ...[
                    _buildGoalCard(goal, isSaving: provider.isSaving),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openGoalForm(),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.textWhite,
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
    );
  }

  Widget _buildSummary(GoalProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved across goals',
            style: TextStyle(
              color: AppColors.textWhite.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatAmount(provider.totalSaved),
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _summaryStat(
                      'Target', _formatAmount(provider.totalTarget))),
              Expanded(
                  child:
                      _summaryStat('Active', '${provider.activeGoalsCount}')),
              Expanded(
                  child: _summaryStat(
                      'Complete', '${provider.completedGoalsCount}')),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.overallProgress / 100,
              minHeight: 7,
              backgroundColor: AppColors.textWhite.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(AppColors.textWhite),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${provider.overallProgress.toStringAsFixed(0)}% overall',
              style: TextStyle(
                color: AppColors.textWhite.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textWhite.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(GoalModel goal, {required bool isSaving}) {
    final progressColor =
        goal.isCompleted ? AppColors.success : AppColors.primaryPurple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Edit goal',
                onPressed: isSaving ? null : () => _openGoalForm(goal: goal),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'Delete goal',
                onPressed: isSaving ? null : () => _deleteGoal(goal),
                color: AppColors.error,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          if (goal.note?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text(
              goal.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatAmount(goal.savedAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${goal.progressPercentage}% of ${_formatAmount(goal.targetAmount)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: progressColor.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _goalStatus(goal)),
              if (!goal.isCompleted)
                OutlinedButton.icon(
                  onPressed: isSaving ? null : () => _addSavings(goal),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Add savings'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalStatus(GoalModel goal) {
    if (goal.isCompleted) {
      return const Text(
        'Goal reached',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (goal.isOverdue) {
      return const Text(
        'Past target date',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (goal.targetDate != null) {
      return Text(
        'Due ${DateFormat('d MMM yyyy').format(goal.targetDate!)}',
        style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
      );
    }
    return Text(
      '${_formatAmount(goal.remainingAmount)} to go',
      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
    );
  }

  Widget _buildEmptyState() {
    final completedView = _showCompleted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      child: Column(
        children: [
          Icon(
            completedView ? Icons.flag_outlined : Icons.savings_outlined,
            size: 44,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            completedView ? 'No completed goals yet' : 'No savings goals yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (!completedView) ...[
            const SizedBox(height: 6),
            const Text(
              'Set a target and start building toward it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Create your first goal',
              icon: Icons.add,
              height: 48,
              onPressed: () => _openGoalForm(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(GoalProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 44, color: AppColors.error),
          const SizedBox(height: 12),
          const Text(
            'Goals could not be loaded',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
          ),
          TextButton.icon(
            onPressed: () {
              provider.clearError();
              provider.refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(GoalProvider provider) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.cloud_off_outlined, color: AppColors.error),
        title: const Text('Could not refresh goals'),
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
}

class _AddSavingsDialog extends StatefulWidget {
  final String goalTitle;
  final double remainingAmount;
  final String remainingAmountLabel;

  const _AddSavingsDialog({
    required this.goalTitle,
    required this.remainingAmount,
    required this.remainingAmountLabel,
  });

  @override
  State<_AddSavingsDialog> createState() => _AddSavingsDialogState();
}

class _AddSavingsDialogState extends State<_AddSavingsDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_controller.text.trim());
    final valid = value != null && value > 0 && value <= widget.remainingAmount;

    return AlertDialog(
      title: Text('Add savings to ${widget.goalTitle}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Amount',
          prefixText: '${AppConstants.currencySymbol} ',
          helperText: 'Up to ${widget.remainingAmountLabel} remaining',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: valid ? () => Navigator.pop(context, value) : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Add savings'),
        ),
      ],
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  final GoalModel? goal;

  const _GoalFormSheet({this.goal});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _noteController;
  DateTime? _targetDate;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _targetController = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: goal?.note ?? '');
    _targetDate = goal?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null && mounted) setState(() => _targetDate = picked);
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final existing = widget.goal;
    final goal = GoalModel(
      id: existing?.id,
      userId: existing?.userId ?? '',
      title: _titleController.text.trim(),
      targetAmount: double.parse(_targetController.text.trim()),
      savedAmount: existing?.savedAmount ?? 0,
      targetDate: _targetDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: existing?.createdAt,
      updatedAt: existing == null ? null : DateTime.now(),
    );

    final provider = context.read<GoalProvider>();
    final success = existing == null
        ? await provider.addGoal(goal)
        : await provider.updateGoal(goal);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = provider.errorMessage ?? 'Could not save this goal.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit savings goal' : 'Create savings goal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Goal name',
                    hintText: 'e.g. Emergency fund',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a goal name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _targetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target amount',
                    prefixText: 'Rs. ',
                    prefixIcon: Icon(Icons.savings_outlined),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter an amount greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target date (optional)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _targetDate == null
                              ? 'No target date'
                              : DateFormat('d MMM yyyy').format(_targetDate!),
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickTargetDate,
                        child: Text(_targetDate == null ? 'Choose' : 'Change'),
                      ),
                      if (_targetDate != null)
                        IconButton(
                          tooltip: 'Clear target date',
                          onPressed: () => setState(() => _targetDate = null),
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  text: isEditing ? 'Save changes' : 'Create goal',
                  icon: isEditing ? Icons.check : Icons.add,
                  isLoading: _isSaving,
                  onPressed: _saveGoal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
