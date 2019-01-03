import '../redurx.dart';

/// Middleware that prints when action's reducers are applied.
class LogMiddleware<T> extends Middleware<T> {

  /// Prints before the Action reducer call.
  @override
  Future<void> beforeAction(action, store) async {
    print('Before action: ${action}: $store.state');
    super.beforeAction(action, store);
    return;
  }

  /// Prints after the Action reducer call.
  @override
  Future<void> afterAction(action, store) async {
    print('After action: ${action.runtimeType}: $store.state');
    super.afterAction(action, store);
    return;
  }
}
