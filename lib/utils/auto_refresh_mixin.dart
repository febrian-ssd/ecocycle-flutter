// lib/utils/auto_refresh_mixin.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';

mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _refreshTimer;
  bool _isAutoRefreshEnabled = true;
  
  // Override this in your widget to define refresh logic
  Future<void> onAutoRefresh() async {}
  
  // Override this to set custom refresh interval (default 30 seconds)
  Duration get refreshInterval => const Duration(seconds: 30);
  
  void startAutoRefresh() {
    if (_isAutoRefreshEnabled) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(refreshInterval, (timer) {
        if (mounted && _isAutoRefreshEnabled) {
          debugPrint('🔄 Auto-refresh triggered for ${widget.runtimeType}');
          onAutoRefresh();
        }
      });
    }
  }
  
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  void toggleAutoRefresh() {
    _isAutoRefreshEnabled = !_isAutoRefreshEnabled;
    if (_isAutoRefreshEnabled) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
  }
  
  // Auto refresh auth data
  Future<void> refreshAuthData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshAllData();
    } catch (e) {
      debugPrint('❌ Auto-refresh auth data failed: $e');
    }
  }
  
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}