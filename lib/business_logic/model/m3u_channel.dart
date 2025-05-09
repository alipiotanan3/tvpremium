import 'package:flutter/foundation.dart';

class M3UChannel {
  final String name;
  final String logo;
  final String category;
  final String url;
  final String? fallbackUrl;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;
  final String type; // 'live', 'movie', 'series'
  final Map<String, String> attributes;

  M3UChannel({
    required this.name,
    required this.logo,
    required this.category,
    required this.url,
    this.fallbackUrl,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
    this.type = 'live',
    Map<String, String>? attributes,
  }) : attributes = attributes ?? {};

  factory M3UChannel.fromM3ULine(String extinf, String url) {
    final attributes = <String, String>{};
    String? fallbackUrl;
    
    // Parse EXTINF attributes
    final attrRegex = RegExp('([a-zA-Z-]+)="([^"]*)"');
    final matches = attrRegex.allMatches(extinf);
    
    for (var match in matches) {
      final key = match.group(1)!;
      final value = match.group(2)!;
      attributes[key] = value;

      // Check for fallback URL in attributes
      if (key == 'backup-url') {
        fallbackUrl = value;
      }
    }

    // Get channel name from the end of EXTINF line
    final nameMatch = RegExp(',[\\s]*(.+)\$').firstMatch(extinf);
    final name = nameMatch?.group(1) ?? 'Unknown Channel';

    // Determine type based on URL or attributes
    String type = 'live';
    if (url.toLowerCase().contains('/movie/') || 
        url.toLowerCase().contains('/vod/') ||
        url.toLowerCase().contains('.mp4')) {
      type = 'movie';
    } else if (url.toLowerCase().contains('/series/')) {
      type = 'series';
    }

    // Get category from group-title or determine from type
    String category = attributes['group-title'] ?? 'Outros';
    if (category == 'Outros') {
      switch (type) {
        case 'movie':
          category = 'Filmes';
          break;
        case 'series':
          category = 'Séries';
          break;
        default:
          category = 'TV ao Vivo';
      }
    }

    return M3UChannel(
      name: name,
      logo: attributes['tvg-logo'] ?? '',
      category: category,
      url: url,
      fallbackUrl: fallbackUrl,
      tvgId: attributes['tvg-id'],
      tvgName: attributes['tvg-name'],
      tvgLogo: attributes['tvg-logo'],
      groupTitle: attributes['group-title'],
      type: type,
      attributes: attributes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is M3UChannel &&
        other.url == url &&
        other.name == name;
  }

  @override
  int get hashCode => url.hashCode ^ name.hashCode;
} 