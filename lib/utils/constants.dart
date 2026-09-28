// utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // ==========================================
  // APP INFO
  // ==========================================
  static const String appName = 'Spendly';
  static const String appTagline = 'Personal Spending Assistant';
  static const String appSlogan = 'Track. Understand. Control. Achieve.';
  static const String appFooter = 'Better money habits for a brighter future';

  // ==========================================
  // PADDING & MARGIN (හැම තැනම use වෙන spacing)
  // ==========================================
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // ==========================================
  // BORDER RADIUS
  // ==========================================
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusRound = 100.0;

  // ==========================================
  // ICON SIZES
  // ==========================================
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // ==========================================
  // BUTTON / FIELD HEIGHTS
  // ==========================================
  static const double buttonHeight = 56.0;
  static const double fieldHeight = 56.0;
  static const double bottomNavHeight = 70.0;

  // ==========================================
  // EXPENSE CATEGORIES
  // ==========================================
  static const String categoryFood = 'Food';
  static const String categoryTransport = 'Transport';
  static const String categoryShopping = 'Shopping';
  static const String categoryBills = 'Bills';
  static const String categoryHealth = 'Health';
  static const String categoryEducation = 'Education';
  static const String categoryEntertainment = 'Entertainment';
  static const String categoryOther = 'Other';

  static const List<String> expenseCategories = [
    categoryFood,
    categoryTransport,
    categoryShopping,
    categoryBills,
    categoryHealth,
    categoryEducation,
    categoryEntertainment,
    categoryOther,
  ];

  // ==========================================
  // CATEGORY ICONS (හැම category එකකට icon එකක්)
  // ==========================================
  static const Map<String, IconData> categoryIcons = {
    categoryFood: Icons.restaurant,
    categoryTransport: Icons.directions_bus,
    categoryShopping: Icons.shopping_bag,
    categoryBills: Icons.receipt_long,
    categoryHealth: Icons.local_hospital,
    categoryEducation: Icons.school,
    categoryEntertainment: Icons.gamepad,
    categoryOther: Icons.more_horiz,
  };

  // ==========================================
  // FIRESTORE COLLECTION NAMES
  // ==========================================
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String budgetsCollection = 'budgets';
  static const String goalsCollection = 'goals';

  // ==========================================
  // FIRESTORE FIELD NAMES
  // ==========================================
  static const String fieldUserId = 'userId';
  static const String fieldTitle = 'title';
  static const String fieldAmount = 'amount';
  static const String fieldCategory = 'category';
  static const String fieldDate = 'date';
  static const String fieldNote = 'note';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldEmail = 'email';
  static const String fieldName = 'name';

  // ==========================================
  // BUDGET
  // ==========================================
  static const double defaultMonthlyBudget = 50000.0;
  static const double budgetWarningThreshold = 0.8; // 80% use වුනාම warning

  // ==========================================
  // CURRENCY & DATE FORMATS
  // ==========================================
  static const String currencySymbol = 'Rs.';
  static const String dateFormatDisplay = 'dd MMM yyyy'; // 27 Sep 2026
  static const String dateFormatShort = 'dd MMM'; // 27 Sep
  static const String dateFormatFull =
      'EEEE, dd MMMM yyyy'; // Monday, 27 September 2026
  static const String monthFormat = 'MMMM yyyy'; // September 2026

  // ==========================================
  // MESSAGES (Snackbar / Error messages)
  // ==========================================
  static const String msgRequiredField = 'This field is required';
  static const String msgInvalidEmail = 'Please enter a valid email';
  static const String msgWeakPassword =
      'Password must be at least 6 characters';
  static const String msgPasswordMismatch = 'Passwords do not match';
  static const String msgLoginSuccess = 'Login successful!';
  static const String msgLoginFailed = 'Invalid email or password';
  static const String msgRegisterSuccess = 'Account created successfully!';
  static const String msgRegisterFailed = 'Registration failed. Try again.';
  static const String msgExpenseAdded = 'Expense added successfully';
  static const String msgExpenseDeleted = 'Expense deleted';
  static const String msgExpenseUpdated = 'Expense updated';
  static const String msgBudgetUpdated = 'Budget updated';
  static const String msgGoalAdded = 'Savings goal added';
  static const String msgLogoutConfirm = 'Are you sure you want to logout?';
  static const String msgNoData = 'No data available';
  static const String msgNoExpenses = 'No expenses yet. Add your first one!';
  static const String msgNoInternet = 'Please check your internet connection';

  // ==========================================
  // LABELS
  // ==========================================
  static const String labelEmail = 'Email';
  static const String labelPassword = 'Password';
  static const String labelConfirmPassword = 'Confirm Password';
  static const String labelName = 'Name';
  static const String labelLogin = 'Login';
  static const String labelRegister = 'Create Account';
  static const String labelLogout = 'Log Out';
  static const String labelForgotPassword = 'Forgot Password?';
  static const String labelAddExpense = 'Add Expense';
  static const String labelEdit = 'Edit';
  static const String labelDelete = 'Delete';
  static const String labelCancel = 'Cancel';
  static const String labelSave = 'Save';
  static const String labelAmount = 'Amount';
  static const String labelCategory = 'Category';
  static const String labelDate = 'Date';
  static const String labelNote = 'Note';
  static const String labelAddReceipt = 'Add Receipt';
  static const String labelTotalBudget = 'Total Budget';
  static const String labelAvailableToSpend = 'Available to Spend';
  static const String labelRecentExpenses = 'Recent Expenses';
  static const String labelSpendingOverview = 'Spending Overview';
  static const String labelSavingsGoal = 'Savings Goal';
  static const String labelSmartTip = 'Smart Tip';

  // ==========================================
  // NAVIGATION LABELS
  // ==========================================
  static const String navHome = 'Home';
  static const String navExpenses = 'Expenses';
  static const String navBudget = 'Budget';
  static const String navInsights = 'Insights';
  static const String navProfile = 'Profile';
  static const String navGoals = 'Goals';
  static const String navSettings = 'Settings';
}
