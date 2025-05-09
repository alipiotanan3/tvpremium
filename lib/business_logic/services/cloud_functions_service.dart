import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:tiwee/business_logic/model/playlist_validation.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Valida uma playlist M3U
  Future<PlaylistValidation> validatePlaylist(String playlistUrl) async {
    try {
      final result = await _functions.httpsCallable('validateM3U').call({
        'url': playlistUrl,
      });

      return PlaylistValidation.fromJson(result.data);
    } catch (e) {
      throw Exception('Erro ao validar playlist: ${e.toString()}');
    }
  }

  /// Monitora o status dos streams em uma playlist
  Future<Map<String, dynamic>> monitorStreams(String playlistUrl) async {
    try {
      final result = await _functions.httpsCallable('monitorStreams').call({
        'url': playlistUrl,
      });

      return result.data;
    } catch (e) {
      throw Exception('Erro ao monitorar streams: ${e.toString()}');
    }
  }

  /// Comprime uma playlist para melhor performance
  Future<Map<String, dynamic>> compressPlaylist(String playlistUrl) async {
    try {
      final result = await _functions.httpsCallable('compressPlaylist').call({
        'url': playlistUrl,
      });

      return result.data;
    } catch (e) {
      throw Exception('Erro ao comprimir playlist: ${e.toString()}');
    }
  }
} 