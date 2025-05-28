// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class ChatUser extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;
  final String role; // admin, delivery, etc.

  const ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    required this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'role': role,
    };
  }

  ChatUser copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isOnline,
    String? lastSeen,
    String? role,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, name, avatar, isOnline, lastSeen, role];
}
