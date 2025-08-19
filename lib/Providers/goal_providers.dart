import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a Notifier that manages a counter
class GoalNotifier extends Notifier<int> {
  @override
  int build() => 0; // initial state

  void set(value) => state = value;
}

// Create the provider
final wtDailyGoalProvider = NotifierProvider<GoalNotifier, int>(GoalNotifier.new);
final wtWeeklyGoalProvider = NotifierProvider<GoalNotifier, int>(GoalNotifier.new);