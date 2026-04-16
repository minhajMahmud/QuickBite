import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../../data/models/chat_message.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class DeliveryChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String orderId;
  final String currentUserId;
  final String currentUserName;
  final String riderName;
  final String? riderAvatar;
  final bool isCustomer;

  const DeliveryChatScreen({
    Key? key,
    required this.conversationId,
    required this.orderId,
    required this.currentUserId,
    required this.currentUserName,
    required this.riderName,
    this.riderAvatar,
    required this.isCustomer,
  }) : super(key: key);

  @override
  ConsumerState<DeliveryChatScreen> createState() => _DeliveryChatScreenState();
}

class _DeliveryChatScreenState extends ConsumerState<DeliveryChatScreen> {
  late ScrollController _scrollController;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = ref.read(authProvider).token;
      if (token == null || token.isEmpty) {
        return;
      }

      await ref
          .read(chatNotifierProvider(widget.conversationId).notifier)
          .loadHistory(
            token: token,
            orderId: widget.orderId,
          );
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _shareCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission finalPermission = permission;

      if (permission == LocationPermission.denied) {
        finalPermission = await Geolocator.requestPermission();
      }

      if (finalPermission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to share location'),
          ),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      if (finalPermission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      String? address;
      try {
        // In production, use a geocoding service
        address = '${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)}';
      } catch (_) {
        address = null;
      }

      final chatNotifier = ref.read(
        chatNotifierProvider(widget.conversationId).notifier,
      );
      final token = ref.read(authProvider).token;
      if (token == null || token.isEmpty) {
        throw Exception('Please log in to share location');
      }

      await chatNotifier.sendLocationMessage(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        isLive: true,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        senderIsCustomer: widget.isCustomer,
        token: token,
        orderId: widget.orderId,
      );

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing location: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _openLocationNavigation(
      double latitude, double longitude) async {
    final navUri = Uri.parse(
      'google.navigation:q=$latitude,$longitude&mode=d',
    );
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening maps: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(
      chatNotifierProvider(widget.conversationId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(chatState),
      body: Column(
        children: [
          // Online status
          if (!chatState.riderOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outlined,
                    color: Colors.orange[700],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.riderName} is currently offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          // Messages list
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation with ${widget.riderName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        ...chatState.messages.map(
                          (message) => ChatBubble(
                            message: message,
                            onLocationTap:
                                message.type == ChatMessageType.location
                                    ? () => _openLocationNavigation(
                                          message.latitude ?? 0,
                                          message.longitude ?? 0,
                                        )
                                    : null,
                          ),
                        ),
                        // Typing indicator
                        if (chatState.riderTyping != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TypingIndicator(
                                riderName: chatState.riderTyping!,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          // Input bar
          ChatInputBar(
            onSendMessage: (text) async {
              final chatNotifier = ref.read(
                chatNotifierProvider(widget.conversationId).notifier,
              );
              final token = ref.read(authProvider).token;
              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please log in to send messages')),
                );
                return;
              }
              await chatNotifier.sendMessage(
                text: text,
                senderId: widget.currentUserId,
                senderName: widget.currentUserName,
                senderIsCustomer: widget.isCustomer,
                token: token,
                orderId: widget.orderId,
              );
              _scrollToBottom();
            },
            onShareLocation: _isLoadingLocation ? () {} : _shareCurrentLocation,
            onAttachFile: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File attachment coming soon'),
                ),
              );
            },
            isLoading: _isLoadingLocation,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatState chatState) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.riderName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            chatState.riderOnline ? 'Online' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      chatState.riderOnline ? Colors.green : Colors.grey[600],
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call feature coming soon')),
            );
          },
          icon: const Icon(Icons.call_rounded),
          tooltip: 'Call rider',
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order details coming soon')),
            );
          },
          icon: const Icon(Icons.info_outlined),
          tooltip: 'Order info',
        ),
      ],
    );
  }
}

class TypingIndicator extends StatefulWidget {
  final String riderName;

  const TypingIndicator({
    Key? key,
    required this.riderName,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -0.5),
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(
            index * 0.15,
            0.15 + (index * 0.15),
            curve: Curves.easeInOut,
          ),
        ),
      );
    }).toList();

    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.riderName} is typing...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SlideTransition(
                  position: _animations[index],
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
