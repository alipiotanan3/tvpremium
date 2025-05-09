import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tiwee/business_logic/model/playlist_quality.dart';

class StreamAnalysisService {
  Future<PlaylistQuality> analyzeStream(String streamUrl) async {
    try {
      // Start stream analysis
      final response = await http.get(Uri.parse(streamUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to access stream');
      }

      // Analyze stream headers and content
      final headers = response.headers;
      final contentLength = response.contentLength ?? 0;
      final contentType = headers['content-type'] ?? '';

      // Extract quality information from headers
      final bitrate = _extractBitrate(headers);
      final resolution = _extractResolution(headers);
      final frameRate = _extractFrameRate(headers);
      final codec = _extractCodec(headers);

      // Determine if stream is HD or 4K
      final isHD = _isHD(resolution);
      final is4K = _is4K(resolution);

      // Determine overall quality
      final quality = _determineQuality(bitrate, resolution, frameRate);

      return PlaylistQuality(
        bitrate: bitrate,
        resolution: resolution,
        frameRate: frameRate,
        codec: codec,
        isHD: isHD,
        is4K: is4K,
        quality: quality,
      );
    } catch (e) {
      throw Exception('Failed to analyze stream: $e');
    }
  }

  double _extractBitrate(Map<String, String> headers) {
    // Extract bitrate from headers or content
    // This is a simplified implementation
    final contentLength = headers['content-length'];
    if (contentLength != null) {
      final bytes = int.tryParse(contentLength) ?? 0;
      return bytes * 8 / 1000; // Convert to kbps
    }
    return 0.0;
  }

  String _extractResolution(Map<String, String> headers) {
    // Extract resolution from headers or content
    // This is a simplified implementation
    final contentRange = headers['content-range'];
    if (contentRange != null && contentRange.contains('x')) {
      final parts = contentRange.split('x');
      if (parts.length == 2) {
        return '${parts[0]}x${parts[1]}';
      }
    }
    return '1920x1080'; // Default to 1080p
  }

  int _extractFrameRate(Map<String, String> headers) {
    // Extract frame rate from headers or content
    // This is a simplified implementation
    final frameRate = headers['x-frame-rate'];
    if (frameRate != null) {
      return int.tryParse(frameRate) ?? 30;
    }
    return 30; // Default to 30fps
  }

  String _extractCodec(Map<String, String> headers) {
    // Extract codec from headers or content
    // This is a simplified implementation
    final contentType = headers['content-type'] ?? '';
    if (contentType.contains('h264')) {
      return 'H.264';
    } else if (contentType.contains('h265')) {
      return 'H.265';
    } else if (contentType.contains('vp9')) {
      return 'VP9';
    }
    return 'H.264'; // Default to H.264
  }

  bool _isHD(String resolution) {
    final parts = resolution.split('x');
    if (parts.length == 2) {
      final height = int.tryParse(parts[1]) ?? 0;
      return height >= 720;
    }
    return false;
  }

  bool _is4K(String resolution) {
    final parts = resolution.split('x');
    if (parts.length == 2) {
      final height = int.tryParse(parts[1]) ?? 0;
      return height >= 2160;
    }
    return false;
  }

  String _determineQuality(double bitrate, String resolution, int frameRate) {
    if (_is4K(resolution)) {
      return '4K';
    } else if (_isHD(resolution)) {
      if (bitrate >= 5000) {
        return 'HD';
      } else {
        return 'SD';
      }
    } else {
      return 'SD';
    }
  }
} 