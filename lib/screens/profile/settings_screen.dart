import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSendingReset = false;

  Future<void> _resetPassword() async {
    final auth = context.read<AuthProvider>();
    final email = auth.userEmail;
    if (email.isEmpty) {
      _showMessage('No email address is available for this account.',
          error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password?'),
        content: Text('Send a password reset link to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    auth.clearError();
    setState(() => _isSendingReset = true);
    final sent = await auth.forgotPassword(email);
    if (!mounted) return;
    setState(() => _isSendingReset = false);
    _showMessage(
      sent
          ? 'Password reset link sent to $email'
          : auth.errorMessage ?? 'Could not send password reset link',
      error: !sent,
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        context.select<AuthProvider, String>((auth) => auth.userEmail);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'Security',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Reset password'),
              subtitle: Text(email.isEmpty ? 'Email unavailable' : email),
              trailing: _isSendingReset
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isSendingReset ? null : _resetPassword,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: const Column(
              children: [
                ExpansionTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('How do I add an expense?'),
                  childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      'Open the Expenses tab and tap +. Enter the amount, '
                      'category, and date, then save.',
                    ),
                  ],
                ),
                Divider(height: 1),
                ExpansionTile(
                  leading: Icon(Icons.pie_chart_outline),
                  title: Text('How do budgets work?'),
                  childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      'Set a monthly limit in Budget. You can also set '
                      'category limits and move between months.',
                    ),
                  ],
                ),
                Divider(height: 1),
                ExpansionTile(
                  leading: Icon(Icons.savings_outlined),
                  title: Text('How do savings goals work?'),
                  childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      'Create a target, then use Add savings to record '
                      'progress. Goals move to Completed when they reach '
                      'their target.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
