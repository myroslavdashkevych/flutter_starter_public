import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/favorites/repositories/favorites_repository.dart';
import 'package:flutter_starter/domain/favorites/usecases/toggle_favorite_use_case.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/_shared/bloc/favorite/favorite_toggle_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class FavoriteToggleCubit extends Cubit<FavoriteToggleState> {
  FavoriteToggleCubit(
    this._authRepository,
    this._favoritesRepository,
    this._toggleFavorite,
  ) : super(const FavoriteToggleState());

  final AuthRepository _authRepository;
  final FavoritesRepository _favoritesRepository;
  final ToggleFavoriteUseCase _toggleFavorite;
  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<bool>? _favoriteSubscription;

  void watch(int itemId) {
    _userSubscription = _authRepository.authStateChanges().listen(
      (user) => emit(state.copyWith(isSignedIn: user != null)),
    );
    _favoriteSubscription = _favoritesRepository
        .watchIsFavorite(itemId)
        .listen((isFavorite) => emit(state.copyWith(isFavorite: isFavorite)));
  }

  Future<void> toggle(Item item) async {
    emit(state.copyWith(failure: null));
    final result = await _toggleFavorite(item);
    if (isClosed) return;
    if (result case Err(:final failure)) {
      emit(state.copyWith(failure: failure));
    }
  }

  @override
  Future<void> close() async {
    await _userSubscription?.cancel();
    await _favoriteSubscription?.cancel();
    return super.close();
  }
}
