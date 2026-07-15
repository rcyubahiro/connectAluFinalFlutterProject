import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames; // uid -> display name
  final String? opportunityId;
  final String? opportunityTitle;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ChatThread({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.opportunityId,
    this.opportunityTitle,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatThread.fromMap(String id, Map<String, dynamic> map) {
    return ChatThread(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? const []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? const {}),
      opportunityId: map['opportunityId'],
      opportunityTitle: map['opportunityTitle'],
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'opportunityId': opportunityId,
      'opportunityTitle': opportunityTitle,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt == null ? null : Timestamp.fromDate(lastMessageAt!),
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }
}
