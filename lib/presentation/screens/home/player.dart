import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:async';
import 'package:shared_preferences.dart';

class Player extends StatefulWidget {
  final String url;
  final String? fallbackUrl;
  final String? name;

  const Player({
    super.key,
    required this.url,
    this.fallbackUrl,
    this.name,
  });

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _bufferingTimer;
  Timer? _qualityCheckTimer;
  int _retryCount = 0;
  bool _isFallbackActive = false;
  double _currentPlaybackQuality = 1.0; // 1.0 = original quality
  static const int _maxRetries = 3;
  static const Duration _bufferingTimeout = Duration(seconds: 10);
  static const Duration _qualityCheckInterval = Duration(seconds: 30);
  
  // Quality monitoring
  int _bufferingEvents = 0;
  DateTime? _lastBufferingEvent;
  bool _isQualityReduced = false;

  @override
  void initState() {
    super.initState();
    _loadPlaybackSettings();
    _initializePlayer();
  }

  Future<void> _loadPlaybackSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPlaybackQuality = prefs.getDouble('playback_quality') ?? 1.0;
    });
  }

  Future<void> _savePlaybackSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_quality', _currentPlaybackQuality);
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final url = _isFallbackActive && widget.fallbackUrl != null 
        ? widget.fallbackUrl! 
        : widget.url;

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    
    try {
      _videoPlayerController.addListener(_onPlayerStateChanged);
      
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        aspectRatio: 16 / 9,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1, 1.25, 1.5, 2],
        showOptions: true,
        additionalOptions: (context) => [
          OptionItem(
            onTap: _showQualityDialog,
            iconData: Icons.high_quality,
            title: 'Quality Settings',
          ),
        ],
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_retryCount < _maxRetries)
                  ElevatedButton(
                    onPressed: _retryPlayback,
                    child: const Text('Retry'),
                  ),
                if (!_isFallbackActive && widget.fallbackUrl != null)
                  ElevatedButton(
                    onPressed: _switchToFallback,
                    child: const Text('Try Backup Stream'),
                  ),
              ],
            ),
          );
        },
      );

      // Start quality monitoring
      _startQualityMonitoring();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
        
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stream Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Original Quality'),
              leading: Radio<double>(
                value: 1.0,
                groupValue: _currentPlaybackQuality,
                onChanged: (value) => _updateQuality(value!),
              ),
            ),
            ListTile(
              title: const Text('Reduced Quality (Better Performance)'),
              leading: Radio<double>(
                value: 0.75,
                groupValue: _currentPlaybackQuality,
                onChanged: (value) => _updateQuality(value!),
              ),
            ),
            ListTile(
              title: const Text('Low Quality (Best Performance)'),
              leading: Radio<double>(
                value: 0.5,
                groupValue: _currentPlaybackQuality,
                onChanged: (value) => _updateQuality(value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuality(double quality) async {
    setState(() {
      _currentPlaybackQuality = quality;
      _isQualityReduced = quality < 1.0;
    });
    await _savePlaybackSettings();
    Navigator.of(context).pop();
    _retryPlayback();
  }

  void _startQualityMonitoring() {
    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = Timer.periodic(_qualityCheckInterval, (timer) {
      if (_bufferingEvents > 5 && !_isQualityReduced) {
        // Show suggestion to reduce quality if buffering frequently
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Experiencing buffering? Try reducing the stream quality'),
              action: SnackBarAction(
                label: 'Adjust',
                onPressed: _showQualityDialog,
              ),
            ),
          );
        }
      }
    });
  }

  void _onPlayerStateChanged() {
    final controller = _videoPlayerController;
    
    if (controller.value.isBuffering) {
      _bufferingTimer?.cancel();
      _bufferingTimer = Timer(_bufferingTimeout, () {
        if (mounted && controller.value.isBuffering) {
          _handleBufferingTimeout();
        }
      });

      // Track buffering events for quality monitoring
      _bufferingEvents++;
      _lastBufferingEvent = DateTime.now();
    } else {
      _bufferingTimer?.cancel();
    }

    if (controller.value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = controller.value.errorDescription ?? 'Unknown error occurred';
      });
      _showErrorSnackBar(_errorMessage);
    }
  }

  void _handleBufferingTimeout() {
    if (_retryCount < _maxRetries) {
      _retryPlayback();
    } else if (!_isFallbackActive && widget.fallbackUrl != null) {
      _switchToFallback();
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Stream buffering timeout';
      });
      _showErrorSnackBar('Stream buffering timeout');
    }
  }

  Future<void> _switchToFallback() async {
    setState(() => _isFallbackActive = true);
    _retryCount = 0;
    await _videoPlayerController.dispose();
    _chewieController?.dispose();
    _initializePlayer();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: _retryCount < _maxRetries ? 'Retry' : 
                (!_isFallbackActive && widget.fallbackUrl != null) ? 'Try Backup' : 'Close',
          onPressed: () {
            if (_retryCount < _maxRetries) {
              _retryPlayback();
            } else if (!_isFallbackActive && widget.fallbackUrl != null) {
              _switchToFallback();
            }
          },
        ),
      ),
    );
  }

  Future<void> _retryPlayback() async {
    _retryCount++;
    await _videoPlayerController.dispose();
    _chewieController?.dispose();
    _initializePlayer();
  }

  @override
  void dispose() {
    _bufferingTimer?.cancel();
    _qualityCheckTimer?.cancel();
    _videoPlayerController.removeListener(_onPlayerStateChanged);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        _videoPlayerController.pause();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: widget.name != null ? Text(
            widget.name!,
            style: const TextStyle(color: Colors.white),
          ) : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.high_quality, color: Colors.white),
              onPressed: _showQualityDialog,
              tooltip: 'Quality Settings',
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: _isLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Loading stream...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : _hasError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: $_errorMessage',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (_retryCount < _maxRetries)
                            ElevatedButton(
                              onPressed: _retryPlayback,
                              child: const Text('Retry'),
                            ),
                          if (!_isFallbackActive && widget.fallbackUrl != null)
                            ElevatedButton(
                              onPressed: _switchToFallback,
                              child: const Text('Try Backup Stream'),
                            ),
                        ],
                      )
                    : _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : const Center(
                            child: Text(
                              'Failed to load video',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}
