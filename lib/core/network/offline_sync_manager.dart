import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_info.dart';

enum SyncState {
  synced,   // 🟢 En línea y sincronizado
  syncing,  // 🟡 Sincronizando datos pendientes
  offline,  // 🔴 Sin conexión a internet
}

class OfflineSyncState {
  final SyncState state;
  final int pendingOperationsCount;
  final DateTime? lastSyncedAt;

  const OfflineSyncState({
    this.state = SyncState.synced,
    this.pendingOperationsCount = 0,
    this.lastSyncedAt,
  });

  OfflineSyncState copyWith({
    SyncState? state,
    int? pendingOperationsCount,
    DateTime? lastSyncedAt,
  }) {
    return OfflineSyncState(
      state: state ?? this.state,
      pendingOperationsCount: pendingOperationsCount ?? this.pendingOperationsCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  final Ref ref;

  OfflineSyncNotifier(this.ref) : super(const OfflineSyncState()) {
    _init();
  }

  void _init() {
    ref.listen<AsyncValue<ConnectionStatus>>(connectionStatusStreamProvider, (_, next) {
      next.whenData((status) {
        if (status == ConnectionStatus.offline) {
          state = state.copyWith(state: SyncState.offline);
        } else {
          if (state.pendingOperationsCount > 0) {
            triggerSync();
          } else {
            state = state.copyWith(
              state: SyncState.synced,
              lastSyncedAt: DateTime.now(),
            );
          }
        }
      });
    });
  }

  void addPendingOperation() {
    state = state.copyWith(
      pendingOperationsCount: state.pendingOperationsCount + 1,
    );
  }

  Future<void> triggerSync() async {
    if (state.pendingOperationsCount == 0) return;
    state = state.copyWith(state: SyncState.syncing);

    // Simulate batch sync upload
    await Future.delayed(const Duration(milliseconds: 1500));

    state = state.copyWith(
      state: SyncState.synced,
      pendingOperationsCount: 0,
      lastSyncedAt: DateTime.now(),
    );
  }
}

final offlineSyncProvider = StateNotifierProvider<OfflineSyncNotifier, OfflineSyncState>((ref) {
  return OfflineSyncNotifier(ref);
});
