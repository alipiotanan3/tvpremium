import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/services/playlist_service.dart';

final playlistServiceProvider = Provider<PlaylistService>((ref) {
  return PlaylistService();
}); 