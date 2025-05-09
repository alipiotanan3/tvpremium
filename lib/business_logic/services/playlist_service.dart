import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tiwee/business_logic/model/playlist.dart';
import 'package:tiwee/business_logic/model/validation_log.dart';

class PlaylistResult {
  final List<Playlist> items;
  final String? lastDocumentId;

  PlaylistResult({
    required this.items,
    this.lastDocumentId,
  });
}

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'playlists';
  final String _logsCollection = 'validation_logs';

  // Get playlists with pagination and filtering
  Future<PlaylistResult> getPlaylists({
    int limit = 10,
    String? startAfter,
    String? searchQuery,
    Set<PlaylistStatus>? statusFilter,
    Set<String>? tagFilter,
  }) async {
    Query query = _firestore.collection(_collection);

    // Apply filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThan: searchQuery + 'z');
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where(
        'status',
        whereIn: statusFilter.map((s) => s.toString()).toList(),
      );
    }

    if (tagFilter != null && tagFilter.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tagFilter.toList());
    }

    // Apply pagination
    if (startAfter != null) {
      final startAfterDoc = await _firestore
          .collection(_collection)
          .doc(startAfter)
          .get();
      query = query.startAfterDocument(startAfterDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    final playlists = snapshot.docs.map((doc) => Playlist.fromFirestore(doc)).toList();

    return PlaylistResult(
      items: playlists,
      lastDocumentId: snapshot.docs.isEmpty ? null : snapshot.docs.last.id,
    );
  }

  // Get all unique tags
  Future<Set<String>> getAllTags() async {
    final snapshot = await _firestore.collection(_collection).get();
    final tags = <String>{};
    
    for (final doc in snapshot.docs) {
      final playlist = Playlist.fromFirestore(doc);
      tags.addAll(playlist.tags);
    }
    
    return tags;
  }

  // Get validation logs for a playlist
  Stream<List<ValidationLog>> getValidationLogs(String playlistId) {
    return _firestore
        .collection(_logsCollection)
        .where('playlistId', isEqualTo: playlistId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ValidationLog.fromFirestore(doc))
            .toList());
  }

  // Get a single playlist by ID
  Future<Playlist?> getPlaylist(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Playlist.fromFirestore(doc);
  }

  // Get the default playlist
  Future<Playlist?> getDefaultPlaylist() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return Playlist.fromFirestore(snapshot.docs.first);
  }

  // Create a new playlist
  Future<String> createPlaylist(Playlist playlist) async {
    final doc = await _firestore.collection(_collection).add(playlist.toFirestore());
    return doc.id;
  }

  // Update an existing playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    await _firestore
        .collection(_collection)
        .doc(playlist.id)
        .update(playlist.toFirestore());
  }

  // Delete a playlist
  Future<void> deletePlaylist(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Set a playlist as default
  Future<void> setDefaultPlaylist(String id) async {
    final batch = _firestore.batch();
    
    // First, remove default status from all playlists
    final snapshot = await _firestore
        .collection(_collection)
        .where('isDefault', isEqualTo: true)
        .get();
    
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    
    // Set the new default playlist
    batch.update(
      _firestore.collection(_collection).doc(id),
      {'isDefault': true}
    );
    
    await batch.commit();
  }

  // Validate a playlist and update its status
  Future<void> validatePlaylist(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) throw Exception('Playlist não encontrada');

    final playlist = Playlist.fromFirestore(doc);
    final startTime = DateTime.now();

    try {
      // TODO: Implement actual M3U validation logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate validation
      final isValid = true;
      final channelCount = 100;
      final categoryCount = {'Filmes': 30, 'Séries': 40, 'Esportes': 30};

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds / 1000;

      // Update playlist status
      await updatePlaylistStatus(
        id,
        isValid ? PlaylistStatus.active : PlaylistStatus.error,
        responseTime: responseTime,
        channelCount: channelCount,
        categoryCount: categoryCount,
      );

      // Create validation log
      await _firestore.collection(_logsCollection).add(
        ValidationLog(
          id: '',
          playlistId: id,
          timestamp: endTime,
          status: isValid ? PlaylistStatus.active : PlaylistStatus.error,
          responseTime: responseTime,
          channelCount: channelCount,
          categoryCount: categoryCount,
          validatedBy: 'system',
        ).toFirestore(),
      );
    } catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds / 1000;

      // Update playlist status with error
      await updatePlaylistStatus(
        id,
        PlaylistStatus.error,
        error: e.toString(),
        responseTime: responseTime,
      );

      // Create validation log with error
      await _firestore.collection(_logsCollection).add(
        ValidationLog(
          id: '',
          playlistId: id,
          timestamp: endTime,
          status: PlaylistStatus.error,
          error: e.toString(),
          responseTime: responseTime,
          channelCount: 0,
          categoryCount: const {},
          validatedBy: 'system',
        ).toFirestore(),
      );

      rethrow;
    }
  }

  // Update playlist status
  Future<void> updatePlaylistStatus(
    String id,
    PlaylistStatus status, {
    String? error,
    double? responseTime,
    int? channelCount,
    Map<String, int>? categoryCount,
  }) async {
    final data = <String, dynamic>{
      'status': status.toString(),
      'lastChecked': FieldValue.serverTimestamp(),
    };

    if (error != null) data['error'] = error;
    if (responseTime != null) data['responseTime'] = responseTime;
    if (channelCount != null) data['channelCount'] = channelCount;
    if (categoryCount != null) data['categoryCount'] = categoryCount;

    await _firestore.collection(_collection).doc(id).update(data);
  }

  // Get playlists by tag
  Stream<List<Playlist>> getPlaylistsByTag(String tag) {
    return _firestore
        .collection(_collection)
        .where('tags', arrayContains: tag)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Playlist.fromFirestore(doc))
            .toList());
  }

  // Add tag to playlist
  Future<void> addTagToPlaylist(String id, String tag) async {
    await _firestore.collection(_collection).doc(id).update({
      'tags': FieldValue.arrayUnion([tag])
    });
  }

  // Remove tag from playlist
  Future<void> removeTagFromPlaylist(String id, String tag) async {
    await _firestore.collection(_collection).doc(id).update({
      'tags': FieldValue.arrayRemove([tag])
    });
  }
} 