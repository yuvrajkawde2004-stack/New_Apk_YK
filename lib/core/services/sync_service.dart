import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'cloudflare_api_service.dart';

/// Service to handle background sync with Cloudflare Workers + D1 SQLite database + Cloudflare R2 backup.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Start the background synchronization process
  void startSync() {
    if (_syncTimer != null && _syncTimer!.isActive) return;

    debugPrint('Starting Cloudflare D1 background sync service...');
    
    // Perform an initial sync immediately
    _performSync();
    
    // Sync every 5 minutes in background
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performSync();
    });
  }

  /// Stop the background synchronization process
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Stopped Cloudflare background sync service.');
  }

  /// Perform the actual synchronization with Cloudflare Workers API
  Future<void> _performSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = await _dbHelper.database;
      
      // 1. SYNC UP (Push local changes)
      final pendingLogs = await db.query(
        'sync_logs',
        where: 'status = ?',
        whereArgs: ['pending'],
      );

      if (pendingLogs.isNotEmpty) {
        debugPrint('Found ${pendingLogs.length} pending sync logs to push.');
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token != null) {
          final result = await CloudflareApiService.pushSyncLogs(pendingLogs, token);
          
          if (result['success'] == true) {
            // Delete synced logs
            final ids = pendingLogs.map((l) => l['id']).toList();
            await db.delete(
              'sync_logs',
              where: 'id IN (${List.filled(ids.length, '?').join(',')})',
              whereArgs: ids,
            );
            debugPrint('Successfully pushed and cleared ${ids.length} sync logs.');
          } else {
            debugPrint('Failed to push sync logs: ${result['message']}');
          }
        } else {
          debugPrint('No auth token found, skipping sync up.');
        }
      }

    } catch (e) {
      debugPrint('Cloudflare Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 3. SYNC DOWN (Full pull on login/reinstall)
  Future<void> performFullSyncDown() async {
    try {
      debugPrint('Starting full sync down from Cloudflare...');
      final remoteData = await CloudflareApiService.fetchSyncDownData();
      if (remoteData != null && remoteData.isNotEmpty) {
        debugPrint('Cloudflare D1 returned sync down data. Populating local DB...');
        await DatabaseHelper.instance.performFullSyncDown(remoteData);
        debugPrint('Full sync down complete.');
      }
    } catch (e) {
      debugPrint('Full sync down failed: $e');
    }
  }

  /// Force an immediate sync
  Future<void> forceSync() async {
    await _performSync();
  }
}
