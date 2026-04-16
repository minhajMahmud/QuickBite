import 'package:equatable/equatable.dart';

enum ChatMessageType {
  text,
  location,
  system,
}

enum MessageStatus {
  sent,
  delivered,
  seen,
}

ChatMessageType _parseChatMessageType(dynamic raw) {
  if (raw is int && raw >= 0 && raw < ChatMessageType.values.length) {
    return ChatMessageType.values[raw];
  }

  final value = raw?.toString().toLowerCase();
  switch (value) {
    case 'location':
      return ChatMessageType.location;
    case 'system':
      return ChatMessageType.system;
    case 'text':
    default:
      return ChatMessageType.text;
  }
}

MessageStatus _parseMessageStatus(dynamic raw) {
  if (raw is int && raw >= 0 && raw < MessageStatus.values.length) {
    return MessageStatus.values[raw];
  }

  final value = raw?.toString().toLowerCase();
  switch (value) {
    case 'delivered':
      return MessageStatus.delivered;
    case 'seen':
      return MessageStatus.seen;
    case 'sent':
    default:
      return MessageStatus.sent;
  }
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final ChatMessageType type;
  final String content; // Text content or location JSON
  final DateTime timestamp;
  final MessageStatus status;
  final bool isCustomer; // true = customer, false = rider

  // Location specific
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool? isLiveLocation;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.status,
    required this.isCustomer,
    this.latitude,
    this.longitude,
    this.address,
    this.isLiveLocation = false,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    ChatMessageType? type,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isCustomer,
    double? latitude,
    double? longitude,
    String? address,
    bool? isLiveLocation,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isCustomer: isCustomer ?? this.isCustomer,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isLiveLocation: isLiveLocation ?? this.isLiveLocation,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      type: _parseChatMessageType(json['type']),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: _parseMessageStatus(json['status']),
      isCustomer: json['isCustomer'] as bool,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      isLiveLocation: json['isLiveLocation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'type': type.index,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'status': status.index,
        'isCustomer': isCustomer,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'isLiveLocation': isLiveLocation,
      };

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatar,
        type,
        content,
        timestamp,
        status,
        isCustomer,
        latitude,
        longitude,
        address,
        isLiveLocation,
      ];
}

class ChatConversation extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final String riderPartnerId;
  final String customerName;
  final String riderName;
  final String? riderAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final bool riderOnline;
  final DateTime? riderLastSeen;

  const ChatConversation({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.riderPartnerId,
    required this.customerName,
    required this.riderName,
    this.riderAvatar,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.riderOnline,
    this.riderLastSeen,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      customerId: json['customerId'] as String,
      riderPartnerId: json['riderPartnerId'] as String,
      customerName: json['customerName'] as String,
      riderName: json['riderName'] as String,
      riderAvatar: json['riderAvatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      riderOnline: json['riderOnline'] as bool? ?? false,
      riderLastSeen: json['riderLastSeen'] != null
          ? DateTime.parse(json['riderLastSeen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'customerId': customerId,
        'riderPartnerId': riderPartnerId,
        'customerName': customerName,
        'riderName': riderName,
        'riderAvatar': riderAvatar,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'riderOnline': riderOnline,
        'riderLastSeen': riderLastSeen?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        orderId,
        customerId,
        riderPartnerId,
        customerName,
        riderName,
        riderAvatar,
        createdAt,
        updatedAt,
        messages,
        riderOnline,
        riderLastSeen,
      ];
}
