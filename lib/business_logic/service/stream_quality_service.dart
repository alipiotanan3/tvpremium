import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tiwee/business_logic/model/playlist_quality.dart';
import 'package:tiwee/business_logic/service/stream_analysis_service.dart';

class StreamQualityService {
  final StreamAnalysisService _analysisService = StreamAnalysisService();
  final _connectivity = Connectivity();
  Timer? _monitoringTimer;
  final Map<String, StreamErrorStats> _errorStats = {};

  // Stream quality preferences
  bool _preferHD = true;
  bool _prefer4K = false;
  double _minBitrate = 2000; // kbps
  int _maxRetries = 3;

  void setPreferences({
    bool? preferHD,
    bool? prefer4K,
    double? minBitrate,
    int? maxRetries,
  }) {
    _preferHD = preferHD ?? _preferHD;
    _prefer4K = prefer4K ?? _prefer4K;
    _minBitrate = minBitrate ?? _minBitrate;
    _maxRetries = maxRetries ?? _maxRetries;
  }

  Future<String> getBestStreamUrl(List<String> streamUrls) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isMobile = connectivityResult == ConnectivityResult.mobile;

    // Adjust preferences based on connection
    if (isMobile) {
      _prefer4K = false;
      _minBitrate = 1500;
    }

    String? bestUrl;
    PlaylistQuality? bestQuality;

    for (final url in streamUrls) {
      try {
        final quality = await _analysisService.analyzeStream(url);
        
        if (_isStreamSuitable(quality)) {
          if (bestQuality == null || _isBetterQuality(quality, bestQuality)) {
            bestQuality = quality;
            bestUrl = url;
          }
        }
      } catch (e) {
        _updateErrorStats(url, e.toString());
      }
    }

    return bestUrl ?? streamUrls.first;
  }

  bool _isStreamSuitable(PlaylistQuality quality) {
    if (quality.bitrate < _minBitrate) return false;
    if (_prefer4K && !quality.is4K) return false;
    if (_preferHD && !quality.isHD && !quality.is4K) return false;
    return true;
  }

  bool _isBetterQuality(PlaylistQuality newQuality, PlaylistQuality currentBest) {
    if (_prefer4K) {
      if (newQuality.is4K && !currentBest.is4K) return true;
      if (!newQuality.is4K && currentBest.is4K) return false;
    }
    
    if (_preferHD) {
      if (newQuality.isHD && !currentBest.isHD) return true;
      if (!newQuality.isHD && currentBest.isHD) return false;
    }

    return newQuality.bitrate > currentBest.bitrate;
  }

  void startMonitoring(String streamUrl) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        await _analysisService.analyzeStream(streamUrl);
        _resetErrorStats(streamUrl);
      } catch (e) {
        _updateErrorStats(streamUrl, e.toString());
      }
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  void _updateErrorStats(String streamUrl, String error) {
    if (!_errorStats.containsKey(streamUrl)) {
      _errorStats[streamUrl] = StreamErrorStats();
    }
    _errorStats[streamUrl]!.addError(error);
  }

  void _resetErrorStats(String streamUrl) {
    _errorStats.remove(streamUrl);
  }

  bool isStreamProblematic(String streamUrl) {
    final stats = _errorStats[streamUrl];
    if (stats == null) return false;
    return stats.errorCount >= _maxRetries;
  }

  List<String> getProblematicStreams() {
    return _errorStats.entries
        .where((entry) => entry.value.errorCount >= _maxRetries)
        .map((entry) => entry.key)
        .toList();
  }
}

class StreamErrorStats {
  int errorCount = 0;
  DateTime? lastError;
  String? lastErrorMessage;

  void addError(String error) {
    errorCount++;
    lastError = DateTime.now();
    lastErrorMessage = error;
  }
} 