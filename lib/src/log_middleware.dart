import '../redurx.dart';

/// Middleware that prints when action's reducers are applied.
class LogMiddleware<T> extends Middleware<T> {
  /// Prints before the Action reducer call.
  @override
  T beforeAction(action, store, state) {
    print('Before action: ${action.runtimeType}: $state');
    return super.beforeAction(action, store, state);
  }

  /// Prints after the Action reducer call.
  @override
  T afterAction(action, store, state) {
    print('After action: ${action.runtimeType}: $state');
    return super.afterAction(action, store, state);
  }
}
