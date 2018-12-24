/// 👌 A thin layer of a Redux-based state manager on top of RxDart.
///
/// Nomi Modifications:
/// - Changed several functions to take/return Store instead of state T,
/// propagating Store through to actions. This enables some powerful features
/// since you can now dispatch from middleware/actions:
/// chaining actions with middleware and dispatching nested actions!!
/// - Deleted the Computation typedef 'cause it's just redundant
/// - Removed Store(state) variable assignments in Store.dispatch, saving memory!
/// (I think?)

library redurx;

import 'dart:async';

import 'package:rxdart/rxdart.dart';

export 'src/log_middleware.dart';

/// Base interface for all action types.
abstract class ActionType {}

/// Action for synchronous requests.
abstract class Action<T> implements ActionType {
  /// Method to perform a synchronous mutation on the state.
  Store<T> reduce(Store<T> store);
}

/// Action for asynchronous requests.
abstract class AsyncAction<T> implements ActionType {
  /// Method to perform a asynchronous mutation on the state.
  Future<Store<T>> reduce(Store<T> store);
}

/// Interface for Middlewares.
abstract class Middleware<T> {
  /// Called before action reducer.
  Store<T> beforeAction(ActionType action, Store<T> store) => store;

  /// Called after action reducer.
  Store<T> afterAction(ActionType action, Store<T> store) => store;
}

/// The heart of the idea, this is where we control the State and dispatch Actions.
class Store<T> {
  /// You can create the Store given an [initialState].
  Store([T initialState])
    : subject = BehaviorSubject<T>(seedValue: initialState);

  /// This is where RxDart comes in, we manage the final state using a [BehaviorSubject].
  final BehaviorSubject<T> subject;

  /// List of middlewares to be applied.
  final List<Middleware<T>> middlewares = [];

  /// Gets the subject stream.
  Stream<T> get stream => subject.stream;

  /// Gets the subject current value/store's current state.
  T get state => subject.value;

  /// Maps the current subject stream to a new Stream.
  Stream<S> map<S>(S convert(T state)) => stream.map(convert);

  /// Dispatches actions that mutates the current state.
  Store<T> dispatch(ActionType action) {
    if (action is Action<T>) {
      /* Simplified...
      final Store<T> afterAction =
          action.reduce(_computeBeforeMiddlewares(action, this));
      final Store<T> afterMiddlewares = _foldAfterActionMiddlewares(
        afterAction, action);
      subject.add(afterMiddlewares.state);
      */
      subject.add(_foldAfterActionMiddlewares(
        action.reduce(_computeBeforeMiddlewares(action, this)), action).state);

    }

    if (action is AsyncAction<T>) {
      action
        .reduce(_computeBeforeMiddlewares(action, this)).then((afterAction) {
        subject.add(_foldAfterActionMiddlewares(
          afterAction, action).state);
      });
    }
    return this;
  }

  /// Adds middlewares to the store.
  Store<T> add(Middleware<T> middleware) {
    middlewares.add(middleware);
    return this;
  }

  /// Closes the stores subject.
  void close() => subject.close();

  Store<T> _computeBeforeMiddlewares(ActionType action, Store<T> store) =>
    middlewares.fold<Store<T>>(
      store, (store, middleware) => middleware.beforeAction(action, store));

  Store<T> _foldAfterActionMiddlewares(
    Store<T> initialValue, ActionType action) =>
    middlewares.fold<Store<T>>(initialValue,
        (store, middleware) => middleware.afterAction(action, store));
}
