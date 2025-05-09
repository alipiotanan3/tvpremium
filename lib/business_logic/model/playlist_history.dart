class PlaylistHistory {
  final String id;
  final DateTime timestamp;
  final String action;
  final String details;
  final Map<String, dynamic> changes;

  PlaylistHistory({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.details,
    required this.changes,
  });

  factory PlaylistHistory.fromJson(Map<String, dynamic> json) {
    return PlaylistHistory(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      changes: json['changes'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'details': details,
      'changes': changes,
    };
  }
} 