class PlaylistValidation {
  final bool valid;
  final PlaylistStats stats;
  final List<PlaylistError> errors;

  PlaylistValidation({
    required this.valid,
    required this.stats,
    required this.errors,
  });

  factory PlaylistValidation.fromJson(Map<String, dynamic> json) {
    return PlaylistValidation(
      valid: json['valid'] ?? false,
      stats: PlaylistStats.fromJson(json['stats'] ?? {}),
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => PlaylistError.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      'stats': stats.toJson(),
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }
}

class PlaylistStats {
  final int total;
  final int tv;
  final int movies;
  final int series;
  final int invalid;

  PlaylistStats({
    required this.total,
    required this.tv,
    required this.movies,
    required this.series,
    required this.invalid,
  });

  factory PlaylistStats.fromJson(Map<String, dynamic> json) {
    return PlaylistStats(
      total: json['total'] ?? 0,
      tv: json['tv'] ?? 0,
      movies: json['movies'] ?? 0,
      series: json['series'] ?? 0,
      invalid: json['invalid'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'tv': tv,
      'movies': movies,
      'series': series,
      'invalid': invalid,
    };
  }
}

class PlaylistError {
  final int line;
  final String error;
  final String? url;
  final String? info;

  PlaylistError({
    required this.line,
    required this.error,
    this.url,
    this.info,
  });

  factory PlaylistError.fromJson(Map<String, dynamic> json) {
    return PlaylistError(
      line: json['line'] ?? 0,
      error: json['error'] ?? '',
      url: json['url'],
      info: json['info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line': line,
      'error': error,
      if (url != null) 'url': url,
      if (info != null) 'info': info,
    };
  }
} 