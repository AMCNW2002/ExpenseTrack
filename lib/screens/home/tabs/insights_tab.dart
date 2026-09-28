// screens/home/tabs/insights_tab.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/finance_calculations.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  // Filter: මාස 3, 6, හෝ 12
  int _selectedMonths = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExpenseProvider>().refresh();
      }
    });
  }

  // ==========================================
  // FORMAT HELPERS
  // ==========================================
  String _formatAmountShort(double amount) {
    final formatter = NumberFormat('#,##0');
    return '${AppConstants.currencySymbol} ${formatter.format(amount)}';
  }

  String _rangeCaption() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final firstMonth = DateTime(now.year, now.month - _selectedMonths + 1);
    final currentLabel = DateFormat('MMM yyyy').format(currentMonth);
    if (_selectedMonths == 1) return currentLabel;
    return '${DateFormat('MMM yyyy').format(firstMonth)} - $currentLabel';
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, expenseProvider, _) {
            return RefreshIndicator(
              onRefresh: () async {
                expenseProvider.refresh();
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
                    // HEADER
                    // ==========================================
                    _buildHeader(),

                    const SizedBox(height: 20),

                    // ==========================================
                    // MONTH FILTER CHIPS
                    // ==========================================
                    _buildMonthFilter(),

                    const SizedBox(height: 20),

                    // ==========================================
                    // SPENDING TREND (Line Chart)
                    // ==========================================
                    _buildSpendingTrend(expenseProvider),

                    const SizedBox(height: 24),

                    // ==========================================
                    // TOP SPENDING CATEGORY (Pie Chart)
                    // ==========================================
                    _buildTopSpendingCategory(expenseProvider),

                    const SizedBox(height: 24),

                    // ==========================================
                    // SUMMARY STATS
                    // ==========================================
                    _buildSummaryStats(expenseProvider),

                    const SizedBox(height: 24),

                    // ==========================================
                    // SMART TIP
                    // ==========================================
                    _buildSmartTip(expenseProvider),

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
  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Understand your spending habits',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MONTH FILTER CHIPS
  // ==========================================
  Widget _buildMonthFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          _buildFilterChip('This Month', 1),
          _buildFilterChip('Last 3M', 3),
          _buildFilterChip('Last 6M', 6),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int months) {
    final bool isSelected = _selectedMonths == months;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMonths = months);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textWhite : AppColors.textMedium,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SPENDING TREND (Line Chart)
  // ==========================================
  Widget _buildSpendingTrend(ExpenseProvider expenseProvider) {
    // Monthly trend data ගන්න
    Map<String, double> trendData =
        expenseProvider.getMonthlyTrend(months: _selectedMonths);

    // Map එකේ values list එකකට convert කරන්න
    List<double> values = trendData.values.toList();
    List<String> labels = trendData.keys.toList();

    // Data නැත්නම් empty state
    if (values.isEmpty || values.every((v) => v == 0)) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelSpendingOverview,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 48,
                    color: AppColors.textLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No trend data yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add expenses to see your spending trend',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // Max value එක (Y-axis සඳහා)
    double maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 1000; // default

    // Spots හදන්න
    List<FlSpot> spots = [];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Last $_selectedMonths months',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 3,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxValue / 3,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            _formatShortNumber(value),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        // සියලු labels පෙන්නන්නේ නැහැ (තදින් තියෙන නිසා)
                        if (labels.length > 4 && index % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxValue * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primaryPurple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.cardWhite,
                          strokeWidth: 2.5,
                          strokeColor: AppColors.primaryPurple,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple.withValues(alpha: 0.3),
                          AppColors.primaryPurple.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppColors.textDark,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          _formatAmountShort(spot.y),
                          const TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP SPENDING CATEGORY (Pie Chart)
  // ==========================================
  Widget _buildTopSpendingCategory(ExpenseProvider expenseProvider) {
    final periodExpenses = expenseProvider.getExpensesForLastMonths(
      months: _selectedMonths,
    );
    final spending = calculateSpendingByCategory(
      periodExpenses,
      categories: AppConstants.expenseCategories,
    );
    final total = totalExpenseAmount(periodExpenses);

    // Amount > 0 categories විතරයි
    Map<String, double> activeSpending = {};
    spending.forEach((category, amount) {
      if (amount > 0) activeSpending[category] = amount;
    });

    // Empty state
    if (activeSpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Spending Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 48,
                    color: AppColors.textLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No data available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add expenses to see category breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // Sort කරලා top items ගන්න
    List<MapEntry<String, double>> sortedList = activeSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pie chart sections හදන්න
    List<PieChartSectionData> sections = [];
    List<Map<String, dynamic>> legendItems = [];

    for (int i = 0; i < sortedList.length; i++) {
      final entry = sortedList[i];
      final percentage = total > 0 ? (entry.value / total) * 100 : 0;
      final color = AppColors.getCategoryColor(entry.key);
      final icon = AppConstants.categoryIcons[entry.key] ?? Icons.more_horiz;

      sections.add(
        PieChartSectionData(
          value: entry.value,
          color: color,
          radius: 40,
          title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.55,
        ),
      );

      legendItems.add({
        'category': entry.key,
        'amount': entry.value,
        'percentage': percentage,
        'color': color,
        'icon': icon,
      });
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _rangeCaption(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatAmountShort(total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 26,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legendItems.take(5).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item['color'] as Color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['category'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(item['percentage'] as double).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SUMMARY STATS
  // ==========================================
  Widget _buildSummaryStats(
    ExpenseProvider expenseProvider,
  ) {
    final periodExpenses = expenseProvider.getExpensesForLastMonths(
      months: _selectedMonths,
    );
    final periodTotal = totalExpenseAmount(periodExpenses);
    final averagePerMonth = periodTotal / _selectedMonths;
    final averagePerExpense =
        periodExpenses.isEmpty ? 0.0 : periodTotal / periodExpenses.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                _rangeCaption(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                label: 'Period total',
                value: _formatAmountShort(periodTotal),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                label: 'Monthly average',
                value: _formatAmountShort(averagePerMonth),
                icon: Icons.calendar_month,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                label: 'Expenses',
                value: '${periodExpenses.length}',
                icon: Icons.receipt_long,
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                label: 'Average expense',
                value: _formatAmountShort(averagePerExpense),
                icon: Icons.calculate_outlined,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SMART TIP
  // ==========================================
  Widget _buildSmartTip(ExpenseProvider expenseProvider) {
    final periodExpenses = expenseProvider.getExpensesForLastMonths(
      months: _selectedMonths,
    );
    final periodTotal = totalExpenseAmount(periodExpenses);
    final categoryTotals = calculateSpendingByCategory(
      periodExpenses,
      categories: AppConstants.expenseCategories,
    );
    final monthlyTotals = expenseProvider.getMonthlyTrend(
      months: _selectedMonths,
    );
    final tip = _getSmartTip(categoryTotals, periodTotal, monthlyTotals);

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

  String _getSmartTip(
    Map<String, double> categoryTotals,
    double periodTotal,
    Map<String, double> monthlyTotals,
  ) {
    if (periodTotal <= 0) {
      return 'Add expenses to see insights for this period.';
    }

    final monthlyValues = monthlyTotals.values.toList();
    if (monthlyValues.length > 1 &&
        monthlyValues[monthlyValues.length - 2] > 0) {
      final previousMonth = monthlyValues[monthlyValues.length - 2];
      final currentMonth = monthlyValues.last;
      final change = ((currentMonth - previousMonth) / previousMonth) * 100;
      if (change >= 10) {
        return 'Spending is ${change.toStringAsFixed(0)}% higher than last month.';
      }
      if (change <= -10) {
        return 'Spending is ${change.abs().toStringAsFixed(0)}% lower than last month.';
      }
    }

    MapEntry<String, double>? topCategory;
    for (final entry in categoryTotals.entries) {
      if (topCategory == null || entry.value > topCategory.value) {
        topCategory = entry;
      }
    }
    if (topCategory == null || topCategory.value <= 0) {
      return 'No category spending was recorded for this period.';
    }

    final share = (topCategory.value / periodTotal) * 100;
    return '${topCategory.key} is your largest category at ${share.toStringAsFixed(0)}% of spending.';
  }

  // ==========================================
  // HELPER: Short Number (1k, 2k, etc.)
  // ==========================================
  String _formatShortNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}
