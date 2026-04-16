import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function() onShareLocation;
  final Function() onAttachFile;
  final bool isLoading;

  const ChatInputBar({
    Key? key,
    required this.onSendMessage,
    required this.onShareLocation,
    required this.onAttachFile,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                // Attach button
                IconButton(
                  onPressed: widget.isLoading ? null : widget.onAttachFile,
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: Colors.grey[600],
                  ),
                  tooltip: 'Attach file',
                ),
                // Location button
                IconButton(
                  onPressed: widget.isLoading ? null : widget.onShareLocation,
                  icon: Icon(
                    Icons.location_on_rounded,
                    color: Colors.grey[600],
                  ),
                  tooltip: 'Share location',
                ),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.isLoading,
                    maxLines: 1,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                // Send button
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final hasText = _controller.text.trim().isNotEmpty;
                      return IconButton(
                        onPressed: widget.isLoading
                            ? null
                            : (hasText ? _handleSend : null),
                        icon: Icon(
                          Icons.send_rounded,
                          color: hasText
                              ? const Color(0xFF0F9D58)
                              : Colors.grey[400],
                        ),
                        tooltip: 'Send message',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

    Future.delayed(Duration.zero, () {
      for (var controller in _controllers) {
        controller.repeat(reverse: true);
      }
    });
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
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
      ),
    );
  }
}

class ChatHeader extends StatelessWidget {
  final String riderName;
  final String? riderAvatar;
  final bool riderOnline;
  final DateTime? riderLastSeen;
  final VoidCallback onBackPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onInfoPressed;

  const ChatHeader({
    Key? key,
    required this.riderName,
    this.riderAvatar,
    required this.riderOnline,
    this.riderLastSeen,
    required this.onBackPressed,
    required this.onCallPressed,
    required this.onInfoPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F9D58).withOpacity(0.1),
              border: Border.all(
                color: riderOnline ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: riderAvatar != null
                ? ClipOval(
                    child: Image.network(
                      riderAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          Icons.person,
                          color: const Color(0xFF0F9D58),
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: const Color(0xFF0F9D58),
                  ),
            // Online indicator
            foregroundDecoration: riderOnline
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Rider info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  riderOnline
                      ? 'Online'
                      : 'Last seen ${_formatLastSeen(riderLastSeen)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: riderOnline ? Colors.green : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          IconButton(
            onPressed: onCallPressed,
            icon: const Icon(Icons.call_rounded),
            tooltip: 'Call rider',
          ),
          IconButton(
            onPressed: onInfoPressed,
            icon: const Icon(Icons.info_outlined),
            tooltip: 'Order info',
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? date) {
    if (date == null) return 'recently';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class OnlineStatusIndicator extends StatefulWidget {
  final bool isOnline;
  final String label;

  const OnlineStatusIndicator({
    Key? key,
    required this.isOnline,
    this.label = 'Online',
  }) : super(key: key);

  @override
  State<OnlineStatusIndicator> createState() => _OnlineStatusIndicatorState();
}

class _OnlineStatusIndicatorState extends State<OnlineStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Offline',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
