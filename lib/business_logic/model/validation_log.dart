import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tiwee/business_logic/model/playlist.dart';

class ValidationLog {
  final String id;
  final String playlistId;
  final DateTime timestamp;
  final PlaylistStatus status;
  final String? error;
  final double responseTime;
  final int channelCount;
  final Map<String, int> categoryCount;
  final String? validatedBy;

  ValidationLog({
    required this.id,
    required this.playlistId,
    required this.timestamp,
    required this.status,
    this.error,
    required this.responseTime,
    required this.channelCount,
    required this.categoryCount,
    this.validatedBy,
  });

  factory ValidationLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ValidationLog(
      id: doc.id,
      playlistId: data['playlistId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: PlaylistStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PlaylistStatus.unknown,
      ),
      error: data['error'] as String?,
      responseTime: (data['responseTime'] as num).toDouble(),
      channelCount: data['channelCount'] as int,
      categoryCount: Map<String, int>.from(data['categoryCount'] as Map),
      validatedBy: data['validatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'playlistId': playlistId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString(),
      'error': error,
      'responseTime': responseTime,
      'channelCount': channelCount,
      'categoryCount': categoryCount,
      'validatedBy': validatedBy,
    };
  }

  factory ValidationLog.fromJson(Map<String, dynamic> json) {
    return ValidationLog(
      id: '',
      playlistId: '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: PlaylistStatus.values.firstWhere(
        (e) => e.toString() == 'PlaylistStatus.${json['status']}',
        orElse: () => PlaylistStatus.unknown,
      ),
      error: json['error'] as String?,
      responseTime: (json['responseTime'] as num).toDouble(),
      channelCount: json['channelCount'] as int,
      categoryCount: {},
      validatedBy: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'error': error,
      'responseTime': responseTime,
      'channelCount': channelCount,
    };
  }
} 