import '../redurx.dart';

/// Middleware that prints when action's reducers are applied.
class LogMiddleware<T> extends Middleware<T> {
  /// Prints before the Action reducer call.
  @override
  T beforeAction(action, store) {
    print('Before action: ${action.runtimeType}: $store.state');
    return super.beforeAction(action, store);
  }

  /// Prints after the Action reducer call.
  @override
  T afterAction(action, store) {
    print('After action: ${action.runtimeType}: $store.state');
    return super.afterAction(action, store);
  }
}
