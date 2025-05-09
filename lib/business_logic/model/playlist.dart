import 'package:cloud_firestore/cloud_firestore.dart';

enum PlaylistStatus {
  active,
  offline,
  slow,
  error,
  unknown,
}

class Playlist {
  final String id;
  final String name;
  final String url;
  final List<String> tags;
  final bool isDefault;
  final PlaylistStatus status;
  final int channelCount;
  final Map<String, int> categoryCount;
  final double responseTime;
  final DateTime lastChecked;
  final String? error;
  final Map<String, dynamic> metadata;

  Playlist({
    required this.id,
    required this.name,
    required this.url,
    required this.tags,
    required this.isDefault,
    required this.status,
    required this.channelCount,
    required this.categoryCount,
    required this.responseTime,
    required this.lastChecked,
    this.error,
    required this.metadata,
  });

  // Create from Firestore document
  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Playlist(
      id: doc.id,
      name: data['name'] as String,
      url: data['url'] as String,
      tags: List<String>.from(data['tags'] as List? ?? []),
      isDefault: data['isDefault'] as bool? ?? false,
      status: PlaylistStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PlaylistStatus.unknown,
      ),
      channelCount: data['channelCount'] as int? ?? 0,
      categoryCount: Map<String, int>.from(data['categoryCount'] as Map? ?? {}),
      responseTime: (data['responseTime'] as num?)?.toDouble() ?? 0,
      lastChecked: (data['lastChecked'] as Timestamp?)?.toDate() ?? DateTime.now(),
      error: data['error'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'url': url,
      'tags': tags,
      'isDefault': isDefault,
      'status': status.toString(),
      'channelCount': channelCount,
      'categoryCount': categoryCount,
      'responseTime': responseTime,
      'lastChecked': Timestamp.fromDate(lastChecked),
      'error': error,
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  Playlist copyWith({
    String? name,
    String? url,
    List<String>? tags,
    bool? isDefault,
    PlaylistStatus? status,
    int? channelCount,
    Map<String, int>? categoryCount,
    double? responseTime,
    DateTime? lastChecked,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      tags: tags ?? this.tags,
      isDefault: isDefault ?? this.isDefault,
      status: status ?? this.status,
      channelCount: channelCount ?? this.channelCount,
      categoryCount: categoryCount ?? this.categoryCount,
      responseTime: responseTime ?? this.responseTime,
      lastChecked: lastChecked ?? this.lastChecked,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  static Future<List<Playlist>> getAll() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('playlists')
        .get();
    
    return snapshot.docs
        .map((doc) => Playlist.fromFirestore(doc))
        .toList();
  }

  static Future<Playlist?> getDefault() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('playlists')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return Playlist.fromFirestore(snapshot.docs.first);
  }

  Future<void> save() async {
    final collection = FirebaseFirestore.instance.collection('playlists');
    
    if (isDefault) {
      // Remove default flag from other playlists
      final batch = FirebaseFirestore.instance.batch();
      final defaultPlaylists = await collection
          .where('isDefault', isEqualTo: true)
          .get();
      
      for (var doc in defaultPlaylists.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    }

    await collection.doc(id).update(toFirestore());
  }

  Future<void> delete() async {
    await FirebaseFirestore.instance
        .collection('playlists')
        .doc(id)
        .delete();
  }

  Future<void> validate() async {
    // We'll implement this later using the existing M3U validation logic
  }
} 