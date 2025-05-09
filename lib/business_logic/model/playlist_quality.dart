class PlaylistQuality {
  final double bitrate;
  final String resolution;
  final int frameRate;
  final String codec;
  final bool isHD;
  final bool is4K;
  final String quality;

  PlaylistQuality({
    required this.bitrate,
    required this.resolution,
    required this.frameRate,
    required this.codec,
    required this.isHD,
    required this.is4K,
    required this.quality,
  });

  factory PlaylistQuality.fromJson(Map<String, dynamic> json) {
    return PlaylistQuality(
      bitrate: json['bitrate']?.toDouble() ?? 0.0,
      resolution: json['resolution'] ?? 'Unknown',
      frameRate: json['frameRate'] ?? 0,
      codec: json['codec'] ?? 'Unknown',
      isHD: json['isHD'] ?? false,
      is4K: json['is4K'] ?? false,
      quality: json['quality'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bitrate': bitrate,
      'resolution': resolution,
      'frameRate': frameRate,
      'codec': codec,
      'isHD': isHD,
      'is4K': is4K,
      'quality': quality,
    };
  }
} 