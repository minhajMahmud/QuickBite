import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../data/models/chat_message.dart';
import '../../../authentication/data/services/api_client.dart';

final Map<String, List<ChatMessage>> _conversationMessages = {};
final Map<String, StreamController<ChatMessage>> _conversationStreams = {};

StreamController<ChatMessage> _streamForConversation(String conversationId) {
  return _conversationStreams.putIfAbsent(
    conversationId,
    () => StreamController<ChatMessage>.broadcast(),
  );
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool riderOnline;
  final String? riderTyping; // null or rider name
  final ChatConversation? conversation;

  const ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
    required this.riderOnline,
    this.riderTyping,
    this.conversation,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? riderOnline,
    String? riderTyping,
    ChatConversation? conversation,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      riderOnline: riderOnline ?? this.riderOnline,
      riderTyping: riderTyping ?? this.riderTyping,
      conversation: conversation ?? this.conversation,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final String conversationId;
  final ApiClient _apiClient;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  bool _historyLoaded = false;

  ChatNotifier({
    required this.conversationId,
    required ApiClient apiClient,
  })  : _apiClient = apiClient,
        super(
          const ChatState(
            messages: [],
            isLoading: true,
            riderOnline: false,
            riderTyping: null,
          ),
        ) {
    _initializeChat();
  }

  void _initializeChat() {
    final existing = _conversationMessages[conversationId] ?? const [];
    state = state.copyWith(
      messages: [...existing],
      isLoading: false,
    );

    _messageSubscription?.cancel();
    _messageSubscription = _streamForConversation(conversationId).stream.listen(
      (incoming) {
        final hasMessage = state.messages.any((m) => m.id == incoming.id);
        if (hasMessage) {
          state = state.copyWith(
            messages: state.messages
                .map((msg) => msg.id == incoming.id ? incoming : msg)
                .toList(),
          );
          return;
        }

        state = state.copyWith(
          messages: [...state.messages, incoming],
        );
      },
    );
  }

  ChatMessageType _parseMessageType(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? 'text';
    switch (raw) {
      case 'location':
        return ChatMessageType.location;
      case 'system':
        return ChatMessageType.system;
      default:
        return ChatMessageType.text;
    }
  }

  MessageStatus _parseMessageStatus(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? 'sent';
    switch (raw) {
      case 'seen':
        return MessageStatus.seen;
      case 'delivered':
        return MessageStatus.delivered;
      default:
        return MessageStatus.sent;
    }
  }

  ChatMessage _messageFromApi(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? conversationId).toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderName: (json['senderName'] ?? 'User').toString(),
      senderAvatar: json['senderAvatar']?.toString(),
      type: _parseMessageType(json['type']),
      content: (json['content'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
      status: _parseMessageStatus(json['status']),
      isCustomer: json['isCustomer'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address']?.toString(),
      isLiveLocation: json['isLiveLocation'] == true,
    );
  }

  Future<void> loadHistory({
    required String token,
    required String orderId,
  }) async {
    if (_historyLoaded) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final raw = await _apiClient.getOrderChatMessages(
        token: token,
        orderId: orderId,
      );
      final parsed = raw.map(_messageFromApi).toList();

      _conversationMessages[conversationId] = parsed;
      state = state.copyWith(messages: parsed, isLoading: false, error: null);
      _historyLoaded = true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _pushMessage(ChatMessage message) {
    final list = _conversationMessages[conversationId] ?? <ChatMessage>[];
    final idx = list.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      list[idx] = message;
    } else {
      list.add(message);
    }
    _conversationMessages[conversationId] = list;
    _streamForConversation(conversationId).add(message);
  }

  Future<void> sendMessage({
    required String text,
    required String senderId,
    required String senderName,
    required bool senderIsCustomer,
    required String token,
    required String orderId,
  }) async {
    final optimisticMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      type: ChatMessageType.text,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isCustomer: senderIsCustomer,
    );

    _pushMessage(optimisticMessage);

    try {
      final created = await _apiClient.sendOrderChatMessage(
        token: token,
        orderId: orderId,
        payload: {
          'type': 'text',
          'content': text,
        },
      );

      final serverMessage = _messageFromApi(created);
      _replaceMessage(optimisticMessage.id, serverMessage);
    } catch (e) {
      _updateMessageStatus(optimisticMessage.id, MessageStatus.seen);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendLocationMessage({
    required double latitude,
    required double longitude,
    required String? address,
    required bool isLive,
    required String senderId,
    required String senderName,
    required bool senderIsCustomer,
    required String token,
    required String orderId,
  }) async {
    final optimisticMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      type: ChatMessageType.location,
      content: 'Shared location',
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isCustomer: senderIsCustomer,
      latitude: latitude,
      longitude: longitude,
      address: address,
      isLiveLocation: isLive,
    );

    _pushMessage(optimisticMessage);

    try {
      final created = await _apiClient.sendOrderChatMessage(
        token: token,
        orderId: orderId,
        payload: {
          'type': 'location',
          'content': 'Shared location',
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'isLiveLocation': isLive,
        },
      );

      final serverMessage = _messageFromApi(created);
      _replaceMessage(optimisticMessage.id, serverMessage);
    } catch (e) {
      _updateMessageStatus(optimisticMessage.id, MessageStatus.seen);
      state = state.copyWith(error: e.toString());
    }
  }

  void _replaceMessage(String oldMessageId, ChatMessage replacement) {
    final list = _conversationMessages[conversationId] ?? <ChatMessage>[];
    final idx = list.indexWhere((m) => m.id == oldMessageId);

    if (idx >= 0) {
      list[idx] = replacement;
    } else {
      final existingIdx = list.indexWhere((m) => m.id == replacement.id);
      if (existingIdx >= 0) {
        list[existingIdx] = replacement;
      } else {
        list.add(replacement);
      }
    }

    _conversationMessages[conversationId] = list;
    _streamForConversation(conversationId).add(replacement);
  }

  void _updateMessageStatus(String messageId, MessageStatus newStatus) {
    final list = _conversationMessages[conversationId] ?? <ChatMessage>[];
    final idx = list.indexWhere((msg) => msg.id == messageId);
    if (idx < 0) return;

    final updated = list[idx].copyWith(status: newStatus);
    list[idx] = updated;
    _conversationMessages[conversationId] = list;
    _streamForConversation(conversationId).add(updated);
  }

  void setRiderOnlineStatus(bool isOnline) {
    state = state.copyWith(riderOnline: isOnline);
  }

  void setRiderTyping(String? riderName) {
    state = state.copyWith(riderTyping: riderName);
  }

  void addReceivedMessage(ChatMessage message) {
    _pushMessage(message);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, conversationId) => ChatNotifier(
    conversationId: conversationId,
    apiClient: ApiClient(),
  ),
);
