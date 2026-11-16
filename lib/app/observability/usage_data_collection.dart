import 'dart:async';

import 'package:flutter_starter/domain/use_case/settings/set_usage_data_collection_use_case.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';

/// Applies the "Share usage data" setting now and on every change. Collection
/// runs only when [collectionAllowed] and the setting are both true.
Future<StreamSubscription<SettingsState>> syncUsageDataCollection({
  required SettingsBloc settingsBloc,
  required bool collectionAllowed,
  required SetUsageDataCollectionUseCase setUsageDataCollection,
}) async {
  Future<void> apply(bool sharing) =>
      setUsageDataCollection((enabled: collectionAllowed && sharing));

  var current = settingsBloc.state.settings.usageDataSharing;
  await apply(current);
  return settingsBloc.stream.listen((state) {
    final sharing = state.settings.usageDataSharing;
    if (sharing == current) return;
    current = sharing;
    unawaited(apply(sharing));
  });
}
