import 'package:flutter/material.dart';
import '../../data/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onLocationTap;

  const ChatBubble({
    Key? key,
    required this.message,
    this.onLocationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustomer = message.isCustomer;

    if (message.type == ChatMessageType.system) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            message.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.type == ChatMessageType.location)
              _LocationMessageBubble(
                message: message,
                isCustomer: isCustomer,
                onTap: onLocationTap,
              )
            else
              _TextMessageBubble(
                message: message,
                isCustomer: isCustomer,
              ),
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isCustomer ? 0 : 8,
                right: isCustomer ? 8 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  if (isCustomer) ...[
                    const SizedBox(width: 4),
                    _MessageStatusTick(status: message.status),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TextMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCustomer;

  const _TextMessageBubble({
    required this.message,
    required this.isCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCustomer
            ? const Color(0xFF0F9D58).withOpacity(0.9)
            : theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isCustomer ? 18 : 4),
          bottomRight: Radius.circular(isCustomer ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isCustomer ? Colors.white : theme.textTheme.bodyMedium?.color,
          height: 1.4,
        ),
      ),
    );
  }
}

class _LocationMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCustomer;
  final VoidCallback? onTap;

  const _LocationMessageBubble({
    required this.message,
    required this.isCustomer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCustomer
              ? const Color(0xFF0F9D58).withOpacity(0.9)
              : theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isCustomer ? 18 : 4),
            bottomRight: Radius.circular(isCustomer ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini map preview
            Container(
              width: 200,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.grey[300],
              ),
              child: Stack(
                children: [
                  // Map placeholder with gradient
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.purple.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  // Pulsing location dot
                  Center(
                    child: _PulsingLocationDot(),
                  ),
                  // Coordinates label
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${message.latitude?.toStringAsFixed(4)}, ${message.longitude?.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Location info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        (message.isLiveLocation ?? false)
                            ? Icons.location_on
                            : Icons.location_on_outlined,
                        size: 16,
                        color: isCustomer
                            ? Colors.white
                            : theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (message.isLiveLocation ?? false)
                              ? 'Live Location (Updating...)'
                              : 'Location Shared',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isCustomer
                                ? Colors.white70
                                : theme.textTheme.labelSmall?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (message.address != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      message.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCustomer
                            ? Colors.white70
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCustomer
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF2563EB),
                        foregroundColor:
                            isCustomer ? Colors.white : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingLocationDot extends StatefulWidget {
  const _PulsingLocationDot();

  @override
  State<_PulsingLocationDot> createState() => _PulsingLocationDotState();
}

class _PulsingLocationDotState extends State<_PulsingLocationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing ring
        ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.8, end: 0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2563EB),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        // Center dot
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF2563EB),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2563EB),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MessageStatusTick extends StatelessWidget {
  final MessageStatus status;

  const MessageStatusTick({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _MessageStatusTick(status: status);
  }
}

class _MessageStatusTick extends StatelessWidget {
  final MessageStatus status;

  const _MessageStatusTick({required this.status});

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    const size = 14.0;

    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.done, size: size, color: color);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: size, color: color);
      case MessageStatus.seen:
        return Icon(
          Icons.done_all,
          size: size,
          color: Colors.blue[300],
        );
    }
  }
}
