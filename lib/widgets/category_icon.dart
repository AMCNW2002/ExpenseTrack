// widgets/category_icon.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

// ==========================================
// 1. CATEGORY ICON (Grid item - Category screen)
// ==========================================
class CategoryIcon extends StatelessWidget {
  final String category;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryIcon({
    super.key,
    required this.category,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = AppColors.getCategoryColor(category);
    final IconData categoryIcon =
        AppConstants.categoryIcons[category] ?? Icons.more_horiz;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: categoryColor.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.1)
                : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? categoryColor : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              // Category Label
              Text(
                category,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? categoryColor : AppColors.textDark,
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
// 2. CATEGORY CHIP (Small - Filter chips)
// ==========================================
class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showIcon;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    // 'All' කියන special chip එකට වෙනම color එකක්
    final bool isAll = category.toLowerCase() == 'all';
    final Color chipColor =
        isAll ? AppColors.primaryPurple : AppColors.getCategoryColor(category);
    final IconData chipIcon = isAll
        ? Icons.apps
        : (AppConstants.categoryIcons[category] ?? Icons.more_horiz);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  chipIcon,
                  size: 16,
                  color: isSelected ? AppColors.textWhite : chipColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.textWhite : chipColor,
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
// 3. CATEGORY LIST TILE (List item - History / Details)
// ==========================================
class CategoryListTile extends StatelessWidget {
  final String category;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CategoryListTile({
    super.key,
    required this.category,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = AppColors.getCategoryColor(category);
    final IconData categoryIcon =
        AppConstants.categoryIcons[category] ?? Icons.more_horiz;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
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
              // Category name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. CATEGORY GRID (Full grid - Category screen)
// ==========================================
class CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String) onCategorySelected;
  final int crossAxisCount;

  const CategoryGrid({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        String category = categories[index];
        return CategoryIcon(
          category: category,
          isSelected: selectedCategory == category,
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

// ==========================================
// 5. CATEGORY HORIZONTAL LIST (Chips row - Filter)
// ==========================================
class CategoryFilterRow extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final bool includeAll;

  const CategoryFilterRow({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.includeAll = true,
  });

  @override
  Widget build(BuildContext context) {
    // 'All' chip එක ඉස්සරහින් add කරන්න
    List<String> displayCategories =
        includeAll ? ['All', ...categories] : categories;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          String category = displayCategories[index];
          return CategoryChip(
            category: category,
            isSelected: selectedCategory == category,
            onTap: () => onCategorySelected(category),
          );
        },
      ),
    );
  }
}
