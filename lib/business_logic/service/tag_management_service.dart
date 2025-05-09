import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tiwee/business_logic/model/playlist_tags.dart';
import 'package:uuid/uuid.dart';

class TagManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Tag Management
  Future<PlaylistTag> createTag({
    required String name,
    required String color,
    String? description,
    required String userId,
  }) async {
    final tag = PlaylistTag(
      id: _uuid.v4(),
      name: name,
      color: color,
      description: description,
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    await _firestore
        .collection('tags')
        .doc(tag.id)
        .set(tag.toJson());

    return tag;
  }

  Future<List<PlaylistTag>> getTags() async {
    final snapshot = await _firestore
        .collection('tags')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PlaylistTag.fromJson(doc.data()))
        .toList();
  }

  Future<void> updateTag(PlaylistTag tag) async {
    await _firestore
        .collection('tags')
        .doc(tag.id)
        .update(tag.toJson());
  }

  Future<void> deleteTag(String tagId) async {
    await _firestore
        .collection('tags')
        .doc(tagId)
        .delete();
  }

  Future<void> addTagToStream(String streamUrl, String tagId) async {
    await _firestore
        .collection('streams')
        .doc(streamUrl)
        .collection('tags')
        .doc(tagId)
        .set({
          'addedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> removeTagFromStream(String streamUrl, String tagId) async {
    await _firestore
        .collection('streams')
        .doc(streamUrl)
        .collection('tags')
        .doc(tagId)
        .delete();
  }

  Future<List<PlaylistTag>> getStreamTags(String streamUrl) async {
    final snapshot = await _firestore
        .collection('streams')
        .doc(streamUrl)
        .collection('tags')
        .get();

    final tagIds = snapshot.docs.map((doc) => doc.id).toList();
    final tags = await Future.wait(
      tagIds.map((id) => _firestore
          .collection('tags')
          .doc(id)
          .get()
          .then((doc) => PlaylistTag.fromJson(doc.data()!)))
    );

    return tags;
  }

  // Permission Management
  Future<UserPermission> grantPermission({
    required String userId,
    required UserRole role,
    required String grantedBy,
  }) async {
    final permission = UserPermission(
      userId: userId,
      role: role.name,
      allowedActions: role.defaultActions,
      grantedAt: DateTime.now(),
      grantedBy: grantedBy,
    );

    await _firestore
        .collection('permissions')
        .doc(userId)
        .set(permission.toJson());

    return permission;
  }

  Future<UserPermission?> getUserPermission(String userId) async {
    final doc = await _firestore
        .collection('permissions')
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return UserPermission.fromJson(doc.data()!);
  }

  Future<void> updatePermission(UserPermission permission) async {
    await _firestore
        .collection('permissions')
        .doc(permission.userId)
        .update(permission.toJson());
  }

  Future<void> revokePermission(String userId) async {
    await _firestore
        .collection('permissions')
        .doc(userId)
        .delete();
  }

  Future<bool> canPerformAction(String userId, String action) async {
    final permission = await getUserPermission(userId);
    if (permission == null) return false;
    return permission.canPerformAction(action);
  }
} 