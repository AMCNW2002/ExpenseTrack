// screens/home/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/goal_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../auth/login_screen.dart';
import '../../profile/profile_screen.dart';
import '../../profile/settings_screen.dart';

class ProfileTab extends StatelessWidget {
  final VoidCallback onBudgetSettings;

  const ProfileTab({super.key, required this.onBudgetSettings});

  // ==========================================
  // LOGOUT
  // ==========================================
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log Out?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          content: const Text(
            AppConstants.msgLogoutConfirm,
            style: TextStyle(
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
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.logout();

      if (!context.mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Could not log out'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Login screen එකට navigate කරන්න
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ==========================================
  // FORMAT AMOUNT
  // ==========================================
  String _formatAmountShort(double amount) {
    if (amount >= 1000000) {
      return 'Rs. ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'Rs. ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return 'Rs. ${amount.toStringAsFixed(0)}';
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer4<AuthProvider, ExpenseProvider, BudgetProvider,
            GoalProvider>(
          builder: (context, auth, expenseProvider, budgetProvider,
              goalProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // ==========================================
                  // HEADER
                  // ==========================================
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // PROFILE CARD
                  // ==========================================
                  _buildProfileCard(context, auth),

                  const SizedBox(height: 20),

                  // ==========================================
                  // STATS CARDS
                  // ==========================================
                  _buildStatsCards(
                    expenseProvider,
                    goalProvider,
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // MENU OPTIONS
                  // ==========================================
                  _buildMenuSection(context),

                  const SizedBox(height: 24),

                  // ==========================================
                  // LOGOUT BUTTON
                  // ==========================================
                  PrimaryButton(
                    text: AppConstants.labelLogout,
                    onPressed: () => _handleLogout(context),
                    icon: Icons.logout,
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    textColor: AppColors.error,
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // APP VERSION
                  // ==========================================
                  Center(
                    child: Column(
                      children: [
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // PROFILE CARD
  // ==========================================
  Widget _buildProfileCard(BuildContext context, AuthProvider auth) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openAccount(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.textWhite.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textWhite.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        auth.userInitials,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textWhite.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit Icon
                  IconButton(
                    tooltip: 'Edit account',
                    onPressed: () => _openAccount(context),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.textWhite.withValues(alpha: 0.2),
                      foregroundColor: AppColors.textWhite,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAccount(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  // ==========================================
  // STATS CARDS
  // ==========================================
  Widget _buildStatsCards(
    ExpenseProvider expenseProvider,
    GoalProvider goalProvider,
  ) {
    return Row(
      children: [
        // Total Expenses
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt_long,
            label: 'Total Expenses',
            value: '${expenseProvider.expenses.length}',
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),

        // Total Spent
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            label: 'Total Spent',
            value: _formatAmountShort(expenseProvider.totalSpentAllTime),
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),

        // Goals
        Expanded(
          child: _buildStatCard(
            icon: Icons.flag_outlined,
            label: 'Goals',
            value: '${goalProvider.totalGoalsCount}',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MENU SECTION
  // ==========================================
  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: 'Account',
            subtitle: 'Manage your account',
            onTap: () => _openAccount(context),
          ),
          const Divider(
            height: 1,
            indent: 60,
            color: AppColors.divider,
          ),
          _buildMenuItem(
            context,
            icon: Icons.tune_outlined,
            title: 'Budget Settings',
            subtitle: 'Configure your budgets',
            onTap: onBudgetSettings,
          ),
          const Divider(
            height: 1,
            indent: 60,
            color: AppColors.divider,
          ),
          _buildMenuItem(
            context,
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Privacy and security',
            onTap: () => _openSettings(context),
          ),
          const Divider(
            height: 1,
            indent: 60,
            color: AppColors.divider,
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () => _openSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textLight,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
