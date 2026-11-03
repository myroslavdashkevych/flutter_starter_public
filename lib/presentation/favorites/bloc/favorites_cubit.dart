import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/favorites/repositories/favorites_repository.dart';
import 'package:flutter_starter/domain/favorites/usecases/toggle_favorite_use_case.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(
    AuthRepository authRepository,
    FavoritesRepository favoritesRepository,
    this._toggleFavorite,
  ) : super(const FavoritesState()) {
    _userSubscription = authRepository.authStateChanges().listen(
      (user) => emit(
        state.copyWith(
          authStatus: user == null
              ? FavoritesAuthStatus.guest
              : FavoritesAuthStatus.signedIn,
        ),
      ),
    );
    _itemsSubscription = favoritesRepository.watchAll().listen(
      (items) => emit(state.copyWith(items: items)),
    );
  }

  final ToggleFavoriteUseCase _toggleFavorite;
  late final StreamSubscription<AppUser?> _userSubscription;
  late final StreamSubscription<List<Item>> _itemsSubscription;

  /// Removes by id, for a screen that could not load the item itself.
  Future<void> remove(int id) async {
    final item = state.items?.where((item) => item.id == id).firstOrNull;
    if (item == null) return;
    emit(state.copyWith(removeFailure: null));
    final result = await _toggleFavorite(item);
    if (isClosed) return;
    if (result case Err(:final failure)) {
      emit(state.copyWith(removeFailure: failure));
    }
  }

  @override
  Future<void> close() async {
    await _userSubscription.cancel();
    await _itemsSubscription.cancel();
    return super.close();
  }
}
