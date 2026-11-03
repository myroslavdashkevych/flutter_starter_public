import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_details_state.freezed.dart';

@freezed
sealed class ItemDetailsState with _$ItemDetailsState {
  const factory ItemDetailsState.loading() = ItemDetailsLoading;

  const factory ItemDetailsState.loaded(Item item) = ItemDetailsLoaded;

  const factory ItemDetailsState.failure(Failure failure) = ItemDetailsFailed;
}
