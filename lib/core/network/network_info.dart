import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus { online, offline }

class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  Stream<ConnectionStatus> get onStatusChange {
    return _connectivity.onConnectivityChanged.map((results) {
      return _hasConnection(results) ? ConnectionStatus.online : ConnectionStatus.offline;
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo(Connectivity());
});

final connectionStatusStreamProvider = StreamProvider<ConnectionStatus>((ref) {
  final network = ref.watch(networkInfoProvider);
  return network.onStatusChange;
});
