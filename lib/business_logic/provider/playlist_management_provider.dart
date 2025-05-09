import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/playlist_quality.dart';
import 'package:tiwee/business_logic/model/playlist_history.dart';
import 'package:tiwee/business_logic/service/playlist_management_service.dart';

final playlistManagementServiceProvider = Provider<PlaylistManagementService>((ref) {
  return PlaylistManagementService();
});

final playlistQualityProvider = FutureProvider.family<PlaylistQuality, String>((ref, streamUrl) async {
  final service = ref.watch(playlistManagementServiceProvider);
  return service.analyzeQuality(streamUrl);
});

final playlistHistoryProvider = FutureProvider.family<List<PlaylistHistory>, String>((ref, playlistUrl) async {
  final service = ref.watch(playlistManagementServiceProvider);
  return service.getHistory(playlistUrl);
});

final recentChangesProvider = FutureProvider<List<PlaylistHistory>>((ref) async {
  final service = ref.watch(playlistManagementServiceProvider);
  return service.getRecentChanges();
});

final playlistBackupsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, playlistUrl) async {
  final service = ref.watch(playlistManagementServiceProvider);
  return service.getBackups(playlistUrl);
});

final recentBackupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(playlistManagementServiceProvider);
  return service.getRecentBackups();
});

final createBackupProvider = FutureProvider.family<String, Map<String, String>>((ref, params) async {
  final service = ref.watch(playlistManagementServiceProvider);
  return service.createBackup(params['playlistUrl']!, params['content']!);
});

final restoreBackupProvider = FutureProvider.family<String, String>((ref, backupId) async {
  final service = ref.watch(playlistManagementServiceProvider);
  return service.restoreBackup(backupId);
});

final deleteBackupProvider = FutureProvider.family<void, String>((ref, backupId) async {
  final service = ref.watch(playlistManagementServiceProvider);
  await service.deleteBackup(backupId);
});

final addHistoryEntryProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(playlistManagementServiceProvider);
  await service.addHistoryEntry(
    params['playlistUrl'] as String,
    params['action'] as String,
    params['details'] as String,
    params['changes'] as Map<String, dynamic>,
  );
}); 