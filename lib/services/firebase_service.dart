// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class FirebaseService {
  // ==========================================
  // SINGLETON PATTERN (එකම instance එක හැම තැනම use කරන්න)
  // ==========================================
  FirebaseService._privateConstructor();
  static final FirebaseService _instance =
      FirebaseService._privateConstructor();
  factory FirebaseService() => _instance;

  // ==========================================
  // FIREBASE INSTANCES
  // ==========================================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // GETTERS
  // ==========================================
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) return _handleAuthException(error);

    final message = error.toString().replaceAll('Exception: ', '').trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('cloud_firestore/not-found')) {
      return 'Cloud Firestore is not set up for this Firebase project yet. Create the database in Firebase Console, then try again.';
    }
    if (normalized.contains('permission-denied')) {
      return 'Firestore denied access. Sign in and deploy this project\'s firestore.rules to the same Firebase project used by the app.';
    }
    if (normalized.contains('unauthenticated') ||
        normalized.contains('user not logged in')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (normalized.contains('unavailable') ||
        normalized.contains('network-request-failed') ||
        normalized.contains('deadline-exceeded') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection timed out')) {
      return 'Could not connect to Spendly. Check your internet connection and try again.';
    }
    if (normalized.contains('resource-exhausted') ||
        normalized.contains('too-many-requests')) {
      return 'There have been too many requests. Wait a moment and try again.';
    }
    if (normalized.contains('failed-precondition')) {
      return 'This query needs a Firestore composite index. In Firebase Console, open Firestore Database > Indexes and create the index for this query, then retry.';
    }
    if (normalized.contains('not-found') ||
        normalized.contains('user-not-found')) {
      return 'The requested account or record could not be found.';
    }
    if (normalized.contains('firebaseexception') ||
        normalized.contains('cloud_firestore/') ||
        normalized.contains('firebase_auth/') ||
        normalized.startsWith('failed to ') ||
        normalized.startsWith('registration failed:') ||
        normalized.startsWith('login failed:')) {
      return 'Something went wrong while contacting Spendly. Please try again.';
    }

    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  // ==========================================
  // AUTH: REGISTER
  // ==========================================
  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth එකේ user account එක හදන්න
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      User? user = credential.user;
      if (user == null) return null;

      // 2. Display name එක set කරන්න (Firebase Auth එකේ)
      await user.updateDisplayName(name);

      // 3. Firestore එකේ user document එක හදන්න
      UserModel newUser = UserModel(
        id: user.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Registration failed: ${e.toString()}';
    }
  }

  // ==========================================
  // AUTH: LOGIN
  // ==========================================
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth එකෙන් sign in කරන්න
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      User? user = credential.user;
      if (user == null) return null;

      // 2. Firestore එකෙන් user ගේ data ටික ගන්න
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // User document එක නැත්නම් අලුතෙන් හදන්න
        UserModel newUser = UserModel(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? email,
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(newUser.toMap());
        return newUser;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Login failed: ${e.toString()}';
    }
  }

  // ==========================================
  // AUTH: LOGOUT
  // ==========================================
  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Logout failed: ${e.toString()}';
    }
  }

  // ==========================================
  // AUTH: FORGOT PASSWORD
  // ==========================================
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Password reset failed: ${e.toString()}';
    }
  }

  // ==========================================
  // GET CURRENT USER DATA (Firestore එකෙන්)
  // ==========================================
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw 'Failed to load user data: ${e.toString()}';
    }
  }

  // ==========================================
  // UPDATE USER PROFILE
  // ==========================================
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      if (currentUserId == null) throw 'User not logged in';

      Map<String, dynamic> updates = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      if (name != null) updates[AppConstants.fieldName] = name;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .update(updates);

      // Firebase Auth එකේ display name එකත් update කරන්න
      if (name != null) {
        await currentUser?.updateDisplayName(name);
      }
    } catch (e) {
      throw 'Profile update failed: ${e.toString()}';
    }
  }

  // ==========================================
  // AUTH ERROR HANDLER (Firebase errors ලස්සන messages වලට)
  // ==========================================
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'Please check your internet connection';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  // ==========================================
  // EXPENSE: ADD NEW EXPENSE
  // ==========================================
  Future<String?> addExpense(ExpenseModel expense) async {
    try {
      if (currentUserId == null) throw 'User not logged in';

      // Expense එකේ userId එක current user ට set කරන්න
      ExpenseModel newExpense = expense.copyWith(userId: currentUserId);

      DocumentReference docRef = await _firestore
          .collection(AppConstants.expensesCollection)
          .add(newExpense.toMap());

      return docRef.id;
    } catch (e) {
      throw 'Failed to add expense: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: GET ALL EXPENSES (Stream - Real-time)
  // ==========================================
  Stream<List<ExpenseModel>> getExpensesStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.expensesCollection)
        .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
        .orderBy(AppConstants.fieldDate, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();
    });
  }

  // ==========================================
  // EXPENSE: GET ALL EXPENSES (Future - One-time)
  // ==========================================
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .orderBy(AppConstants.fieldDate, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Failed to load expenses: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: GET EXPENSES BY CATEGORY
  // ==========================================
  Future<List<ExpenseModel>> getExpensesByCategory(String category) async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .where(AppConstants.fieldCategory, isEqualTo: category)
          .orderBy(AppConstants.fieldDate, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Failed to load category expenses: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: GET EXPENSES BY MONTH
  // ==========================================
  Future<List<ExpenseModel>> getExpensesByMonth(int month, int year) async {
    try {
      if (currentUserId == null) return [];

      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .where(AppConstants.fieldDate,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(AppConstants.fieldDate,
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy(AppConstants.fieldDate, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Failed to load monthly expenses: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: GET SINGLE EXPENSE BY ID
  // ==========================================
  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.expensesCollection)
          .doc(expenseId)
          .get();

      if (!doc.exists) return null;

      return ExpenseModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw 'Failed to load expense: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: UPDATE EXPENSE
  // ==========================================
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      if (expense.id == null) throw 'Expense ID is required';

      await _firestore
          .collection(AppConstants.expensesCollection)
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      throw 'Failed to update expense: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: DELETE EXPENSE
  // ==========================================
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore
          .collection(AppConstants.expensesCollection)
          .doc(expenseId)
          .delete();
    } catch (e) {
      throw 'Failed to delete expense: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: GET TOTAL SPENT (මාසයට අදාළව)
  // ==========================================
  Future<double> getTotalSpent({int? month, int? year}) async {
    try {
      if (currentUserId == null) return 0.0;

      DateTime now = DateTime.now();
      int m = month ?? now.month;
      int y = year ?? now.year;

      DateTime startDate = DateTime(y, m, 1);
      DateTime endDate = DateTime(y, m + 1, 0, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .where(AppConstants.fieldDate,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(AppConstants.fieldDate,
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        total +=
            ((doc.data() as Map<String, dynamic>)[AppConstants.fieldAmount] ??
                    0)
                .toDouble();
      }
      return total;
    } catch (e) {
      throw 'Failed to calculate total: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: GET SPENDING BY CATEGORY (මාසයට)
  // ==========================================
  Future<Map<String, double>> getSpendingByCategory({
    int? month,
    int? year,
  }) async {
    try {
      Map<String, double> categoryTotals = {};

      // හැම category එකකටම 0.0 වලින් පටන් ගන්න
      for (String cat in AppConstants.expenseCategories) {
        categoryTotals[cat] = 0.0;
      }

      if (currentUserId == null) return categoryTotals;

      DateTime now = DateTime.now();
      int m = month ?? now.month;
      int y = year ?? now.year;

      DateTime startDate = DateTime(y, m, 1);
      DateTime endDate = DateTime(y, m + 1, 0, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .where(AppConstants.fieldDate,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(AppConstants.fieldDate,
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String category = data[AppConstants.fieldCategory] ?? 'Other';
        double amount = (data[AppConstants.fieldAmount] ?? 0).toDouble();

        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      throw 'Failed to calculate category spending: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: GET RECENT EXPENSES (Last N items)
  // ==========================================
  Future<List<ExpenseModel>> getRecentExpenses({int limit = 5}) async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .orderBy(AppConstants.fieldCreatedAt, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Failed to load recent expenses: ${e.toString()}';
    }
  }

  // ==========================================
  // EXPENSE: SEARCH EXPENSES (Title එකෙන්)
  // ==========================================
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    try {
      if (currentUserId == null || query.trim().isEmpty) return [];

      // Firestore එකේ text search නැහැ, ඒ නිසා ඔක්කොම ගෙන filter කරමු
      List<ExpenseModel> allExpenses = await getExpenses();

      String lowerQuery = query.toLowerCase();
      return allExpenses.where((expense) {
        return expense.title.toLowerCase().contains(lowerQuery) ||
            expense.category.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw 'Search failed: ${e.toString()}';
    }
  }

  // ==========================================
  // BUDGET: CREATE OR UPDATE BUDGET
  // ==========================================
  Future<void> saveBudget(BudgetModel budget) async {
    try {
      if (currentUserId == null) throw 'User not logged in';

      // Budget එකේ userId එක current user ට set කරන්න
      BudgetModel newBudget = budget.copyWith(userId: currentUserId);

      // Month + Year එකට unique doc ID එකක් හදන්න
      String docId = '${currentUserId}_${newBudget.monthYearKey}';

      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(docId)
          .set(newBudget.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save budget: ${e.toString()}';
    }
  }

  // ==========================================
  // BUDGET: GET BUDGET BY MONTH/YEAR
  // ==========================================
  Future<BudgetModel?> getBudget({int? month, int? year}) async {
    try {
      if (currentUserId == null) return null;

      DateTime now = DateTime.now();
      int m = month ?? now.month;
      int y = year ?? now.year;

      String monthYearKey = '${y}_${m.toString().padLeft(2, '0')}';
      String docId = '${currentUserId}_$monthYearKey';

      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(docId)
          .get();

      if (!doc.exists) return null;

      return BudgetModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw 'Failed to load budget: ${e.toString()}';
    }
  }

  // ==========================================
  // BUDGET: GET BUDGET STREAM (Real-time)
  // ==========================================
  Stream<BudgetModel?> getBudgetStream({int? month, int? year}) {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    DateTime now = DateTime.now();
    int m = month ?? now.month;
    int y = year ?? now.year;

    String monthYearKey = '${y}_${m.toString().padLeft(2, '0')}';
    String docId = '${currentUserId}_$monthYearKey';

    return _firestore
        .collection(AppConstants.budgetsCollection)
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return BudgetModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  // ==========================================
  // BUDGET: UPDATE TOTAL BUDGET ONLY
  // ==========================================
  Future<void> updateTotalBudget(double totalBudget,
      {int? month, int? year}) async {
    try {
      if (currentUserId == null) throw 'User not logged in';

      DateTime now = DateTime.now();
      int m = month ?? now.month;
      int y = year ?? now.year;

      String monthYearKey = '${y}_${m.toString().padLeft(2, '0')}';
      String docId = '${currentUserId}_$monthYearKey';

      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(docId)
          .set({
        AppConstants.fieldUserId: currentUserId,
        'totalBudget': totalBudget,
        'month': m,
        'year': y,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update budget: ${e.toString()}';
    }
  }

  // ==========================================
  // BUDGET: UPDATE CATEGORY BUDGET
  // ==========================================
  Future<void> updateCategoryBudget(
    String category,
    double amount, {
    int? month,
    int? year,
  }) async {
    try {
      if (currentUserId == null) throw 'User not logged in';

      // දැනට තියෙන budget එක ගන්න
      BudgetModel? existing = await getBudget(month: month, year: year);

      DateTime now = DateTime.now();
      int m = month ?? now.month;
      int y = year ?? now.year;

      if (existing == null) {
        // Budget එක නැත්නම් අලුතෙන් හදන්න
        BudgetModel newBudget = BudgetModel(
          userId: currentUserId!,
          totalBudget: 0,
          categoryBudgets: {category: amount},
          month: m,
          year: y,
        );
        await saveBudget(newBudget);
      } else {
        // Budget එක තියෙනවා නම් update කරන්න
        BudgetModel updated = existing.updateCategoryBudget(category, amount);
        await saveBudget(updated);
      }
    } catch (e) {
      throw 'Failed to update category budget: ${e.toString()}';
    }
  }

  // ==========================================
  // BUDGET: DELETE BUDGET
  // ==========================================
  Future<void> deleteBudget({int? month, int? year}) async {
    try {
      if (currentUserId == null) throw 'User not logged in';

      DateTime now = DateTime.now();
      int m = month ?? now.month;
      int y = year ?? now.year;

      String monthYearKey = '${y}_${m.toString().padLeft(2, '0')}';
      String docId = '${currentUserId}_$monthYearKey';

      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(docId)
          .delete();
    } catch (e) {
      throw 'Failed to delete budget: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: ADD NEW GOAL
  // ==========================================
  Future<String?> addGoal(GoalModel goal) async {
    try {
      if (currentUserId == null) throw 'User not logged in';

      GoalModel newGoal = goal.copyWith(userId: currentUserId);

      DocumentReference docRef = await _firestore
          .collection(AppConstants.goalsCollection)
          .add(newGoal.toMap());

      return docRef.id;
    } catch (e) {
      throw 'Failed to add goal: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: GET ALL GOALS (Stream - Real-time)
  // ==========================================
  Stream<List<GoalModel>> getGoalsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.goalsCollection)
        .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
        .orderBy(AppConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ==========================================
  // GOAL: GET ALL GOALS (Future - One-time)
  // ==========================================
  Future<List<GoalModel>> getGoals() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.goalsCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .orderBy(AppConstants.fieldCreatedAt, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GoalModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Failed to load goals: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: GET SINGLE GOAL BY ID
  // ==========================================
  Future<GoalModel?> getGoalById(String goalId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.goalsCollection)
          .doc(goalId)
          .get();

      if (!doc.exists) return null;

      return GoalModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw 'Failed to load goal: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: UPDATE GOAL (Full update)
  // ==========================================
  Future<void> updateGoal(GoalModel goal) async {
    try {
      if (goal.id == null) throw 'Goal ID is required';

      await _firestore
          .collection(AppConstants.goalsCollection)
          .doc(goal.id)
          .update({
        AppConstants.fieldTitle: goal.title,
        'targetAmount': goal.targetAmount,
        'targetDate': goal.targetDate == null
            ? null
            : Timestamp.fromDate(goal.targetDate!),
        AppConstants.fieldNote: goal.note,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw 'Failed to update goal: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: ADD AMOUNT TO SAVED (Progress update)
  // ==========================================
  Future<void> addToGoalSaved(String goalId, double amount) async {
    try {
      if (currentUserId == null) throw 'User not logged in';
      if (amount <= 0) throw 'Savings amount must be greater than zero';

      await _firestore
          .collection(AppConstants.goalsCollection)
          .doc(goalId)
          .update({
        'savedAmount': FieldValue.increment(amount),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw 'Failed to update saved amount: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: DELETE GOAL
  // ==========================================
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestore
          .collection(AppConstants.goalsCollection)
          .doc(goalId)
          .delete();
    } catch (e) {
      throw 'Failed to delete goal: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: GET TOTAL SAVED ACROSS ALL GOALS
  // ==========================================
  Future<double> getTotalSaved() async {
    try {
      if (currentUserId == null) return 0.0;

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.goalsCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += ((doc.data() as Map<String, dynamic>)['savedAmount'] ?? 0)
            .toDouble();
      }
      return total;
    } catch (e) {
      throw 'Failed to calculate total saved: ${e.toString()}';
    }
  }

  // ==========================================
  // GOAL: GET ACTIVE GOALS COUNT
  // ==========================================
  Future<int> getActiveGoalsCount() async {
    try {
      if (currentUserId == null) return 0;

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.goalsCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .get();

      int active = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double saved = (data['savedAmount'] ?? 0).toDouble();
        double target = (data['targetAmount'] ?? 0).toDouble();
        if (saved < target) active++;
      }
      return active;
    } catch (e) {
      throw 'Failed to count active goals: ${e.toString()}';
    }
  }

  // ==========================================
  // ANALYTICS: GET DASHBOARD SUMMARY
  // ==========================================
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      if (currentUserId == null) {
        return {
          'totalSpent': 0.0,
          'totalBudget': 0.0,
          'totalSaved': 0.0,
          'activeGoals': 0,
        };
      }

      DateTime now = DateTime.now();
      double totalSpent = await getTotalSpent(month: now.month, year: now.year);
      BudgetModel? budget = await getBudget(month: now.month, year: now.year);
      double totalSaved = await getTotalSaved();
      int activeGoals = await getActiveGoalsCount();

      return {
        'totalSpent': totalSpent,
        'totalBudget': budget?.totalBudget ?? 0.0,
        'availableToSpend': (budget?.totalBudget ?? 0.0) - totalSpent,
        'totalSaved': totalSaved,
        'activeGoals': activeGoals,
        'percentage': budget != null ? budget.getPercentage(totalSpent) : 0.0,
      };
    } catch (e) {
      throw 'Failed to load dashboard: ${e.toString()}';
    }
  }
}
