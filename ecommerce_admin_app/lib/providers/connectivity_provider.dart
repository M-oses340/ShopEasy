import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  Timer? _debounce;

  ConnectivityProvider() {
    _checkInitialStatus();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  /// Checks the initial connectivity state when the app starts
  Future<void> _checkInitialStatus() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  /// Updates internal connection state and notifies listeners
  void _updateStatus(List<ConnectivityResult> results) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      // Determine if any network is available
      final connected = results.any((r) => r != ConnectivityResult.none);

      // (Optional) Check actual internet access (not just Wi-Fi connection)
      final hasInternet = connected ? await _hasInternetAccess() : false;

      if (hasInternet != _isOnline) {
        _isOnline = hasInternet;
        notifyListeners();
      }
    });
  }

  /// Retry manually (used by Retry button)
  Future<void> retry() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  /// Real internet check — confirms actual connectivity
  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
