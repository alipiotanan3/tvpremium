import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/playlist_validation.dart';
import 'package:tiwee/business_logic/services/cloud_functions_service.dart';

final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  return CloudFunctionsService();
});

final playlistValidationProvider = FutureProvider.family<PlaylistValidation, String>((ref, playlistUrl) async {
  final service = ref.watch(cloudFunctionsServiceProvider);
  return service.validatePlaylist(playlistUrl);
});

final streamMonitoringProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, playlistUrl) async {
  final service = ref.watch(cloudFunctionsServiceProvider);
  return service.monitorStreams(playlistUrl);
});

final playlistCompressionProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, playlistUrl) async {
  final service = ref.watch(cloudFunctionsServiceProvider);
  return service.compressPlaylist(playlistUrl);
}); 