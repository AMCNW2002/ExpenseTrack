// providers/goal_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/firebase_service.dart';

class GoalProvider extends ChangeNotifier {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  final FirebaseService _service = FirebaseService();
  StreamSubscription<List<GoalModel>>? _goalSubscription;

  // ==========================================
  // STATE VARIABLES
  // ==========================================
  List<GoalModel> _goals = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // ==========================================
  // GETTERS
  // ==========================================
  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Active goals (ඉවර වෙලා නැති ඒවා)
  List<GoalModel> get activeGoals {
    return _goals.where((goal) => !goal.isCompleted).toList();
  }

  /// Completed goals (ඉවර කරපු ඒවා)
  List<GoalModel> get completedGoals {
    return _goals.where((goal) => goal.isCompleted).toList();
  }

  /// Total goals count
  int get totalGoalsCount => _goals.length;

  /// Active goals count
  int get activeGoalsCount => activeGoals.length;

  /// Completed goals count
  int get completedGoalsCount => completedGoals.length;

  /// Total saved amount (හැම goal එකකම)
  double get totalSaved {
    return _goals.fold(0.0, (sum, goal) => sum + goal.savedAmount);
  }

  /// Total target amount (හැම goal එකකම)
  double get totalTarget {
    return _goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  /// Overall progress percentage (හැම goal එකකම එකතුව)
  double get overallProgress {
    if (totalTarget <= 0) return 0.0;
    double p = (totalSaved / totalTarget) * 100;
    return p.clamp(0.0, 100.0);
  }

  /// Remaining to save (හැම goal එකකම ඉතුරු)
  double get totalRemaining {
    double remaining = totalTarget - totalSaved;
    return remaining > 0 ? remaining : 0.0;
  }

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  GoalProvider() {
    _initGoalStream();
  }

  // ==========================================
  // INIT: Start real-time goal listener
  // ==========================================
  void _initGoalStream() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _goalSubscription?.cancel();

    _goalSubscription = _service.getGoalsStream().listen(
      (goals) {
        _goals = goals;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = FirebaseService.friendlyError(error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================
  @override
  void dispose() {
    _goalSubscription?.cancel();
    super.dispose();
  }

  // ==========================================
  // CLEAR ERROR
  // ==========================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==========================================
  // ADD GOAL
  // ==========================================
  Future<bool> addGoal(GoalModel goal) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addGoal(goal);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // UPDATE GOAL
  // ==========================================
  Future<bool> updateGoal(GoalModel goal) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateGoal(goal);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // DELETE GOAL
  // ==========================================
  Future<bool> deleteGoal(String goalId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteGoal(goalId);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // ADD AMOUNT TO GOAL (Progress update)
  // ==========================================
  Future<bool> addToGoal(String goalId, double amount) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addToGoalSaved(goalId, amount);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // GET GOAL BY ID
  // ==========================================
  GoalModel? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((goal) => goal.id == goalId);
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // SORT GOALS (Progress එක අනුව)
  // ==========================================
  List<GoalModel> get goalsByProgress {
    List<GoalModel> sorted = List.from(activeGoals);
    sorted.sort((a, b) => b.progress.compareTo(a.progress));
    return sorted;
  }

  // ==========================================
  // SORT GOALS (Target date අනුව)
  // ==========================================
  List<GoalModel> get goalsByDeadline {
    List<GoalModel> sorted = List.from(activeGoals);
    sorted.sort((a, b) {
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      return a.targetDate!.compareTo(b.targetDate!);
    });
    return sorted;
  }

  // ==========================================
  // GET COMPLETION PERCENTAGE (හැම goal එකට)
  // ==========================================
  int getProgressPercentage(String goalId) {
    GoalModel? goal = getGoalById(goalId);
    return goal?.progressPercentage ?? 0;
  }

  // ==========================================
  // CHECK IF ANY GOAL IS COMPLETED TODAY
  // ==========================================
  bool get hasRecentCompletion {
    DateTime now = DateTime.now();
    return completedGoals.any((goal) {
      DateTime updated = goal.updatedAt ?? goal.createdAt;
      return updated.year == now.year &&
          updated.month == now.month &&
          updated.day == now.day;
    });
  }

  // ==========================================
  // GET MOTIVATIONAL MESSAGE
  // ==========================================
  String get motivationalMessage {
    if (_goals.isEmpty) {
      return 'Start your first savings goal today! 💪';
    }

    if (completedGoalsCount > 0) {
      return 'Great job! You completed $completedGoalsCount goal(s) 🎉';
    }

    if (overallProgress >= 75) {
      return 'You are almost there! Keep going 🚀';
    }

    if (overallProgress >= 50) {
      return 'Halfway there! Stay focused 💪';
    }

    if (overallProgress >= 25) {
      return 'Good progress! Keep saving 💰';
    }

    return 'Every small saving counts! 🌱';
  }

  // ==========================================
  // REFRESH
  // ==========================================
  void refresh() {
    _initGoalStream();
  }
}
