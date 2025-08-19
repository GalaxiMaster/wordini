import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a Notifier that manages a counter
class GoalNotifier extends Notifier<Map> {
  @override
  Map build() => {}; // initial state

  void set(value) => state = value;
}

// Create the provider
final wtGoalProvider = NotifierProvider<GoalNotifier, Map>(GoalNotifier.new);
