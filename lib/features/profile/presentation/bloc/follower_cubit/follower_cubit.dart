import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/profile/data/datasources/follower_service.dart';
import 'package:migozz_app/features/profile/data/domain/models/follower_dto.dart';

// ============================================================================
// ESTADOS
// ============================================================================

enum FollowerStatus { initial, loading, success, error }

class FollowerState {
  final FollowerStatus status;
  final List<FollowerDTO> followers;
  final List<FollowerDTO> following;
  final int followersCount;
  final int followingCount;
  final Map<String, bool> isFollowingMap; // userId -> isFollowing
  final Map<String, bool> isMutualMap; // userId -> isMutual
  final String? errorMessage;

  const FollowerState({
    this.status = FollowerStatus.initial,
    this.followers = const [],
    this.following = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowingMap = const {},
    this.isMutualMap = const {},
    this.errorMessage,
  });

  FollowerState copyWith({
    FollowerStatus? status,
    List<FollowerDTO>? followers,
    List<FollowerDTO>? following,
    int? followersCount,
    int? followingCount,
    Map<String, bool>? isFollowingMap,
    Map<String, bool>? isMutualMap,
    String? errorMessage,
  }) {
    return FollowerState(
      status: status ?? this.status,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowingMap: isFollowingMap ?? this.isFollowingMap,
      isMutualMap: isMutualMap ?? this.isMutualMap,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// CUBIT
// ============================================================================

class FollowerCubit extends Cubit<FollowerState> {
  final FollowerService _service;
  String? _currentUserId;

  StreamSubscription<int>? _followersCountSub;
  StreamSubscription<int>? _followingCountSub;

  FollowerCubit(this._service) : super(const FollowerState());

  /// Inicializar con el ID del usuario actual
  void initialize(String currentUserId) {
    _currentUserId = currentUserId;
    _listenToCounters(currentUserId);
  }

  /// Escuchar cambios en los contadores
  void _listenToCounters(String userId) {
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();

    _followersCountSub = _service.watchFollowersCount(userId).listen((count) {
      emit(state.copyWith(followersCount: count));
    });

    _followingCountSub = _service.watchFollowingCount(userId).listen((count) {
      emit(state.copyWith(followingCount: count));
    });
  }

  /// Cargar lista de seguidores
  Future<void> loadFollowers(String userId) async {
    emit(state.copyWith(status: FollowerStatus.loading));

    try {
      final followers = await _service.getFollowers(userId);

      // Verificar cuáles son follows mutuos
      final mutualMap = <String, bool>{};
      for (final follower in followers) {
        final isMutual = await _service.isFollowing(
          currentUserId: userId,
          targetUserId: follower.oderId,
        );
        mutualMap[follower.oderId] = isMutual;
      }

      emit(
        state.copyWith(
          status: FollowerStatus.success,
          followers: followers,
          isMutualMap: {...state.isMutualMap, ...mutualMap},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FollowerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Cargar lista de siguiendo
  Future<void> loadFollowing(String userId) async {
    emit(state.copyWith(status: FollowerStatus.loading));

    try {
      final following = await _service.getFollowing(userId);

      emit(
        state.copyWith(status: FollowerStatus.success, following: following),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FollowerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Seguir a un usuario
  Future<bool> followUser(String targetUserId) async {
    if (_currentUserId == null) return false;

    try {
      await _service.followUser(
        currentUserId: _currentUserId!,
        targetUserId: targetUserId,
      );

      // Actualizar mapa de estado
      final newMap = Map<String, bool>.from(state.isFollowingMap);
      newMap[targetUserId] = true;

      emit(
        state.copyWith(
          isFollowingMap: newMap,
          followingCount: state.followingCount + 1,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('❌ [FollowerCubit] Error following: $e');
      return false;
    }
  }

  /// Dejar de seguir a un usuario
  Future<bool> unfollowUser(String targetUserId) async {
    if (_currentUserId == null) return false;

    try {
      await _service.unfollowUser(
        currentUserId: _currentUserId!,
        targetUserId: targetUserId,
      );

      // Actualizar mapa de estado
      final newMap = Map<String, bool>.from(state.isFollowingMap);
      newMap[targetUserId] = false;

      // Actualizar lista de following
      final newFollowing = state.following
          .where((f) => f.oderId != targetUserId)
          .toList();

      emit(
        state.copyWith(
          isFollowingMap: newMap,
          following: newFollowing,
          followingCount: state.followingCount > 0
              ? state.followingCount - 1
              : 0,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('❌ [FollowerCubit] Error unfollowing: $e');
      return false;
    }
  }

  /// Eliminar seguidor
  Future<bool> removeFollower(String followerUserId) async {
    if (_currentUserId == null) return false;

    try {
      await _service.removeFollower(
        currentUserId: _currentUserId!,
        followerUserId: followerUserId,
      );

      // Actualizar lista de followers
      final newFollowers = state.followers
          .where((f) => f.oderId != followerUserId)
          .toList();

      emit(
        state.copyWith(
          followers: newFollowers,
          followersCount: state.followersCount > 0
              ? state.followersCount - 1
              : 0,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('❌ [FollowerCubit] Error removing follower: $e');
      return false;
    }
  }

  /// Verificar si sigue a un usuario
  Future<bool> checkIsFollowing(String targetUserId) async {
    if (_currentUserId == null) return false;

    // Primero revisar el cache
    if (state.isFollowingMap.containsKey(targetUserId)) {
      return state.isFollowingMap[targetUserId]!;
    }

    try {
      final isFollowing = await _service.isFollowing(
        currentUserId: _currentUserId!,
        targetUserId: targetUserId,
      );

      // Guardar en cache
      final newMap = Map<String, bool>.from(state.isFollowingMap);
      newMap[targetUserId] = isFollowing;
      emit(state.copyWith(isFollowingMap: newMap));

      return isFollowing;
    } catch (e) {
      debugPrint('❌ [FollowerCubit] Error checking follow: $e');
      return false;
    }
  }

  /// Verificar si es follow mutuo
  Future<bool> checkIsMutual(String targetUserId) async {
    if (_currentUserId == null) return false;

    // Primero revisar el cache
    if (state.isMutualMap.containsKey(targetUserId)) {
      return state.isMutualMap[targetUserId]!;
    }

    try {
      final isMutual = await _service.isMutualFollow(
        userId1: _currentUserId!,
        userId2: targetUserId,
      );

      // Guardar en cache
      final newMap = Map<String, bool>.from(state.isMutualMap);
      newMap[targetUserId] = isMutual;
      emit(state.copyWith(isMutualMap: newMap));

      return isMutual;
    } catch (e) {
      debugPrint('❌ [FollowerCubit] Error checking mutual: $e');
      return false;
    }
  }

  /// Obtener contadores
  Future<void> loadCounts(String userId) async {
    try {
      final counts = await Future.wait([
        _service.getFollowersCount(userId),
        _service.getFollowingCount(userId),
      ]);

      emit(
        state.copyWith(followersCount: counts[0], followingCount: counts[1]),
      );
    } catch (e) {
      debugPrint('❌ [FollowerCubit] Error loading counts: $e');
    }
  }

  /// Resetear estado
  void reset() {
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();
    _currentUserId = null;
    emit(const FollowerState());
  }

  @override
  Future<void> close() {
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();
    return super.close();
  }
}
