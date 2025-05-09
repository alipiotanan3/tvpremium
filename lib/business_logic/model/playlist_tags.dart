import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistTag {
  final String id;
  final String name;
  final String color;
  final String? description;
  final DateTime createdAt;
  final String createdBy;

  PlaylistTag({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
    required this.createdBy,
  });

  factory PlaylistTag.fromJson(Map<String, dynamic> json) {
    return PlaylistTag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      description: json['description'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}

class UserPermission {
  final String userId;
  final String role;
  final List<String> allowedActions;
  final DateTime grantedAt;
  final String grantedBy;

  UserPermission({
    required this.userId,
    required this.role,
    required this.allowedActions,
    required this.grantedAt,
    required this.grantedBy,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      userId: json['userId'] as String,
      role: json['role'] as String,
      allowedActions: List<String>.from(json['allowedActions']),
      grantedAt: (json['grantedAt'] as Timestamp).toDate(),
      grantedBy: json['grantedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'allowedActions': allowedActions,
      'grantedAt': Timestamp.fromDate(grantedAt),
      'grantedBy': grantedBy,
    };
  }

  bool canPerformAction(String action) {
    return allowedActions.contains(action);
  }
}

enum UserRole {
  admin,
  editor,
  viewer,
}

extension UserRoleExtension on UserRole {
  List<String> get defaultActions {
    switch (this) {
      case UserRole.admin:
        return [
          'create_playlist',
          'edit_playlist',
          'delete_playlist',
          'manage_users',
          'view_playlist',
          'manage_tags',
          'manage_backups',
        ];
      case UserRole.editor:
        return [
          'edit_playlist',
          'view_playlist',
          'manage_tags',
          'create_backup',
          'restore_backup',
        ];
      case UserRole.viewer:
        return [
          'view_playlist',
        ];
    }
  }
} 