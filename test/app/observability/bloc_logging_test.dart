import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/observability/bloc_logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';

sealed class _CounterEvent {
  const _CounterEvent();
}

final class _CounterIncremented extends _CounterEvent {
  const _CounterIncremented();
}

final class _CounterFailed extends _CounterEvent {
  const _CounterFailed();
}

class _CounterBloc extends Bloc<_CounterEvent, int> {
  _CounterBloc() : super(0) {
    on<_CounterEvent>(
      (event, emit) => switch (event) {
        _CounterIncremented() => emit(state + 1),
        _CounterFailed() => addError(StateError('boom'), StackTrace.current),
      },
      transformer: sequential(),
    );
  }
}

void main() {
  /// Runs one transition and one error under the observer of [flavor] and
  /// returns the keys of what Talker logged.
  Future<List<String?>> logKeys(Flavor flavor) async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final previousObserver = Bloc.observer;
    Bloc.observer = createBlocObserver(talker: talker, flavor: flavor);
    addTearDown(() => Bloc.observer = previousObserver);

    final bloc = _CounterBloc()
      ..add(const _CounterIncremented())
      ..add(const _CounterFailed());
    await bloc.close();

    return talker.history.map((data) => data.key).toList();
  }

  test('OBS-6: prod logs Bloc errors but no transitions', () async {
    final keys = await logKeys(Flavor.prod);

    expect(keys, contains(TalkerKey.error));
    expect(keys, isNot(contains(TalkerKey.blocEvent)));
    expect(keys, isNot(contains(TalkerKey.blocTransition)));
  });

  test('OBS-6: dev logs Bloc transitions', () async {
    final keys = await logKeys(Flavor.dev);

    expect(keys, contains(TalkerKey.blocEvent));
    expect(keys, contains(TalkerKey.blocTransition));
    expect(keys, contains(TalkerKey.error));
  });
}
