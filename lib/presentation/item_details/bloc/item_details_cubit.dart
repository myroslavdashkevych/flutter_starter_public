import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/items/usecases/get_item_details_use_case.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class ItemDetailsCubit extends Cubit<ItemDetailsState> {
  ItemDetailsCubit(this._getItemDetails, this._analytics)
    : super(const ItemDetailsState.loading());

  final GetItemDetailsUseCase _getItemDetails;
  final AnalyticsService _analytics;

  /// Loads the item the user has just opened. A retry calls [load] only.
  /// [onLoaded] runs once the item is shown, not after a failure.
  Future<void> open(int id, {void Function()? onLoaded}) async {
    unawaited(
      _analytics.logEvent(
        AnalyticsEvents.selectContent,
        parameters: {
          AnalyticsParams.contentType: AnalyticsValues.itemContentType,
          AnalyticsParams.itemId: id.toString(),
        },
      ),
    );
    await load(id);
    if (!isClosed && state is ItemDetailsLoaded) onLoaded?.call();
  }

  Future<void> load(int id) async {
    emit(const ItemDetailsState.loading());
    final result = await _getItemDetails(id);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => ItemDetailsState.loaded(value),
      Err(:final failure) => ItemDetailsState.failure(failure),
    });
  }
}
