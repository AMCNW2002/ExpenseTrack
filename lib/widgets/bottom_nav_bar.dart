// widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

// ==========================================
// MAIN BOTTOM NAV BAR
// ==========================================
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddPressed;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  _NavBarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: AppConstants.navHome,
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavBarItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: AppConstants.navExpenses,
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  const SizedBox(width: 68),
                  _NavBarItem(
                    icon: Icons.pie_chart_outline,
                    activeIcon: Icons.pie_chart,
                    label: AppConstants.navBudget,
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavBarItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: AppConstants.navInsights,
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
              Positioned(
                top: -16,
                child: Tooltip(
                  message: 'Add expense',
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Material(
                      color: AppColors.primaryPurple,
                      shape: const CircleBorder(),
                      elevation: 5,
                      shadowColor:
                          AppColors.primaryPurple.withValues(alpha: 0.35),
                      child: InkWell(
                        onTap: onAddPressed,
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.textWhite,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// NAV BAR ITEM (Single item)
// ==========================================
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primaryPurple.withValues(alpha: 0.1),
        highlightColor: AppColors.primaryPurple.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryPurple.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primaryPurple : AppColors.textLight,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primaryPurple : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// FLOATING BOTTOM NAV (Optional - With Add button)
// ==========================================
class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddPressed;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Nav Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: AppConstants.navHome,
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavBarItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: AppConstants.navExpenses,
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  // හිස් තැන (Floating button සඳහා)
                  const SizedBox(width: 60),
                  _NavBarItem(
                    icon: Icons.pie_chart_outline,
                    activeIcon: Icons.pie_chart,
                    label: AppConstants.navBudget,
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavBarItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: AppConstants.navInsights,
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),

              // Floating Add Button
              Positioned(
                top: -20,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAddPressed,
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textWhite,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
