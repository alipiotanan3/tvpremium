import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/service/stream_quality_service.dart';
import 'package:tiwee/business_logic/service/tag_management_service.dart';
import 'package:tiwee/business_logic/model/playlist_tags.dart';

final streamQualityServiceProvider = Provider<StreamQualityService>((ref) {
  return StreamQualityService();
});

final tagManagementServiceProvider = Provider<TagManagementService>((ref) {
  return TagManagementService();
});

final streamQualityPreferencesProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'preferHD': true,
    'prefer4K': false,
    'minBitrate': 2000.0,
    'maxRetries': 3,
  };
});

final tagsProvider = FutureProvider<List<PlaylistTag>>((ref) async {
  final service = ref.watch(tagManagementServiceProvider);
  return service.getTags();
});

final streamTagsProvider = FutureProvider.family<List<PlaylistTag>, String>((ref, streamUrl) async {
  final service = ref.watch(tagManagementServiceProvider);
  return service.getStreamTags(streamUrl);
});

final userPermissionProvider = FutureProvider.family<UserPermission?, String>((ref, userId) async {
  final service = ref.watch(tagManagementServiceProvider);
  return service.getUserPermission(userId);
});

final canPerformActionProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final service = ref.watch(tagManagementServiceProvider);
  return service.canPerformAction(params['userId']!, params['action']!);
});

final bestStreamUrlProvider = FutureProvider.family<String, List<String>>((ref, streamUrls) async {
  final service = ref.watch(streamQualityServiceProvider);
  final preferences = ref.watch(streamQualityPreferencesProvider);
  
  service.setPreferences(
    preferHD: preferences['preferHD'],
    prefer4K: preferences['prefer4K'],
    minBitrate: preferences['minBitrate'],
    maxRetries: preferences['maxRetries'],
  );
  
  return service.getBestStreamUrl(streamUrls);
});

final problematicStreamsProvider = Provider<List<String>>((ref) {
  final service = ref.watch(streamQualityServiceProvider);
  return service.getProblematicStreams();
}); 