/// 👌 A thin layer of a Redux-based state manager on top of RxDart.
///
/// Nomi Modifications:
/// - Basically rebuilt the entire fucking thing to support two additional
///   goals: simultaneously running multiple actions with asynchronous calls,
///   and composition of actions. This primarily demands that state is passed
///   into reducers for updates only AFTER asynchronous calls, through
///   middleware, are injected into the action. Probably spent a week finding a
///   generalized solution that doesn't have race failures >_<

library redurx;

import 'dart:async';
import 'package:rxdart/rxdart.dart';

export 'src/log_middleware.dart';

/// Action for synchronous requests.
abstract class Action<T> {
  /// Method to perform a synchronous mutation on the state.
  T reduce(T state);
}

/// Interface for Middlewares.
abstract class Middleware<T> {
  /// Called before action reducer.
  Future<void> beforeAction(Action action, Store<T> store) async => null;

  /// Called after action reducer.
  Future<void> afterAction(Action action, Store<T> store) async  => null;
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
  Future<void> dispatch(Action action) async {

    // Computes beforeAction, which exist to inject asynchronous things into
    // action - doesn't return state
    await _computeBeforeActions(action, this).then((_) {
      print('returning action!');
      subject.add(action.reduce(state));
      print(state);
    });

    // Computes beforeActions, which exist to pass data externally
    await _computeAfterActions(action, this);

    return;
  }

  /// Adds middlewares to the store.
  void add(Middleware<T> middleware) {
    middlewares.add(middleware);
    return;
  }

  /// Closes the stores subject.
  void close() => subject.close();

  Future<void> _computeBeforeActions(Action action, Store<T> store) async {

    for (Middleware middleware in middlewares) {
      await middleware.beforeAction(action, store);
    }

    /* Curiously doesn't work - forEach evaluates synchronously!!
    await middlewares.forEach((middleware) async {
      await middleware.beforeAction(action, store);
    });
    */
  }

  Future<void> _computeAfterActions(Action action, Store<T> store) async {
    for (Middleware middleware in middlewares) {
      await middleware.afterAction(action, store);
    }
  }
}
