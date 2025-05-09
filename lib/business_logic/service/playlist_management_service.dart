import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiwee/business_logic/model/playlist_quality.dart';
import 'package:tiwee/business_logic/model/playlist_history.dart';
import 'package:tiwee/business_logic/service/stream_analysis_service.dart';
import 'package:uuid/uuid.dart';

class PlaylistManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final StreamAnalysisService _streamAnalysis = StreamAnalysisService();
  final _uuid = const Uuid();

  // Quality Analysis
  Future<PlaylistQuality> analyzeQuality(String streamUrl) async {
    try {
      return await _streamAnalysis.analyzeStream(streamUrl);
    } catch (e) {
      throw Exception('Failed to analyze stream quality: $e');
    }
  }

  // History Management
  Future<void> addHistoryEntry(String playlistUrl, String action, String details, Map<String, dynamic> changes) async {
    try {
      final history = PlaylistHistory(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        action: action,
        details: details,
        changes: changes,
      );

      await _firestore
          .collection('playlists')
          .doc(playlistUrl)
          .collection('history')
          .doc(history.id)
          .set(history.toJson());

      // Add to recent changes collection for quick access
      await _firestore
          .collection('recent_changes')
          .doc(history.id)
          .set({
            ...history.toJson(),
            'playlistUrl': playlistUrl,
          });
    } catch (e) {
      throw Exception('Failed to add history entry: $e');
    }
  }

  Future<List<PlaylistHistory>> getHistory(String playlistUrl) async {
    try {
      final snapshot = await _firestore
          .collection('playlists')
          .doc(playlistUrl)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlaylistHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get history: $e');
    }
  }

  Future<List<PlaylistHistory>> getRecentChanges() async {
    try {
      final snapshot = await _firestore
          .collection('recent_changes')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => PlaylistHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent changes: $e');
    }
  }

  // Backup Management
  Future<String> createBackup(String playlistUrl, String content) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final backupId = _uuid.v4();
      final backupPath = 'backups/$playlistUrl/$backupId.json';

      // Create backup metadata
      final backupData = {
        'id': backupId,
        'timestamp': timestamp,
        'playlistUrl': playlistUrl,
        'content': content,
        'size': content.length,
        'streamCount': _countStreams(content),
      };

      // Upload to Firebase Storage
      final ref = _storage.ref().child(backupPath);
      await ref.putString(jsonEncode(backupData));

      // Add to Firestore for easy querying
      await _firestore
          .collection('playlists')
          .doc(playlistUrl)
          .collection('backups')
          .doc(backupId)
          .set(backupData);

      // Add to recent backups collection
      await _firestore
          .collection('recent_backups')
          .doc(backupId)
          .set({
            ...backupData,
            'playlistUrl': playlistUrl,
          });

      return backupId;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBackups(String playlistUrl) async {
    try {
      final snapshot = await _firestore
          .collection('playlists')
          .doc(playlistUrl)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get backups: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentBackups() async {
    try {
      final snapshot = await _firestore
          .collection('recent_backups')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get recent backups: $e');
    }
  }

  Future<String> restoreBackup(String backupId) async {
    try {
      final backupDoc = await _firestore
          .collectionGroup('backups')
          .where('id', isEqualTo: backupId)
          .get();

      if (backupDoc.docs.isEmpty) {
        throw Exception('Backup not found');
      }

      return backupDoc.docs.first.data()['content'] as String;
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  Future<void> deleteBackup(String backupId) async {
    try {
      final backupDoc = await _firestore
          .collectionGroup('backups')
          .where('id', isEqualTo: backupId)
          .get();

      if (backupDoc.docs.isEmpty) {
        throw Exception('Backup not found');
      }

      final backup = backupDoc.docs.first;
      final backupPath = 'backups/${backup.data()['playlistUrl']}/$backupId.json';

      // Delete from Storage
      await _storage.ref().child(backupPath).delete();

      // Delete from Firestore
      await backup.reference.delete();

      // Delete from recent backups
      await _firestore
          .collection('recent_backups')
          .doc(backupId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  int _countStreams(String content) {
    return content.split('\n').where((line) => line.trim().startsWith('http')).length;
  }
} 