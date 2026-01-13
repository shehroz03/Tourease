import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/ai_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/tour_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _tourService = TourService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _isUploadingImage = false;
  bool _isAskingAi = false;
  late Stream<List<MessageModel>> _messageStream;

  UserModel? _otherUser;
  String? _tourTitle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _messageStream = _chatService.streamMessages(widget.chatId);
    _loadChatInfo();
  }

  Future<void> _loadChatInfo() async {
    try {
      final chat = await _chatService.getChatById(widget.chatId);
      if (!mounted) return;

      if (chat != null) {
        final currentUser = context.read<AuthProvider>().user;
        final otherUserId =
            (currentUser?.role == UserRole.traveler ||
                currentUser?.role == UserRole.admin)
            ? chat.agencyId
            : chat.travelerId;

        final otherUser = await _authService.getUserById(otherUserId);
        final tour = await _tourService.getTourById(chat.tourId);

        if (mounted) {
          setState(() {
            _otherUser = otherUser;
            _tourTitle = tour?.title;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: user.id,
        text: text,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Restore the text if sending failed
        _messageController.text = text;
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (_isLoading || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_otherUser?.name ?? 'Chat'),
            if (_tourTitle != null)
              Text(
                _tourTitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (itemContext, index) {
                    final message = messages[index];
                    final isMe = message.senderId == user.id;

                    return GestureDetector(
                      onLongPress: () async {
                        if (message.deleted) return;
                        if (message.senderId != user.id) return;
                        final action = await showModalBottomSheet<String>(
                          context: itemContext,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit'),
                                  onTap: () => Navigator.pop(ctx, 'edit'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text('Delete'),
                                  onTap: () => Navigator.pop(ctx, 'delete'),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (action == 'edit') {
                          if (!itemContext.mounted) return;
                          final controller = TextEditingController(
                            text: message.text,
                          );
                          final confirmed = await showDialog<bool>(
                            context: itemContext,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Edit message'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                maxLines: null,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            if (!mounted) return;
                            try {
                              await _chatService.editMessage(
                                chatId: widget.chatId,
                                messageId: message.id,
                                newText: controller.text.trim(),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Message updated'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        } else if (action == 'delete') {
                          if (!itemContext.mounted) return;
                          final confirmed = await showDialog<bool>(
                            context: itemContext,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete message'),
                              content: const Text(
                                'Are you sure you want to delete this message?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            if (!mounted) return;
                            try {
                              await _chatService.deleteMessage(
                                chatId: widget.chatId,
                                messageId: message.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Message deleted'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      child: _MessageBubble(
                        message: message,
                        isMe: isMe,
                        onImageTap: message.imageUrl != null
                            ? () => _showImage(context, message.imageUrl!)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: _isUploadingImage
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo),
                    onPressed: _isUploadingImage ? null : _pickAndSendImage,
                  ),
                  IconButton(
                    icon: _isAskingAi
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.smart_toy_outlined),
                    tooltip: 'Ask AI',
                    onPressed: _isAskingAi ? null : _askAi,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;
      setState(() => _isUploadingImage = true);

      final bytes = await picked.readAsBytes();
      final fileName = picked.name;
      final url = await CloudinaryService.uploadFromBytes(
        bytes: bytes,
        fileName: fileName,
        folder: 'chats',
      );

      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: user.id,
        text: '',
        imageUrl: url,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _askAi() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final prompt = _messageController.text.trim();
    String finalPrompt = prompt;

    if (finalPrompt.isEmpty) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ask AI'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type a question for the AI...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ask'),
            ),
          ],
        ),
      );
      if (confirmed == true) finalPrompt = controller.text.trim();
    }

    if (finalPrompt.isEmpty) return;

    // Send the user's message (so the chat history has the question)
    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: user.id,
        text: finalPrompt,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Ask AI via Gemini
    setState(() => _isAskingAi = true);
    try {
      final aiService = AiService();
      aiService.ensureInitialized();
      final aiReply = await aiService.sendMessage(finalPrompt);
      // Save AI reply as a message with a special senderId
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: 'ai',
        text: aiReply,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI request failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAskingAi = false);
    }
  }

  void _showImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) =>
          Dialog(child: InteractiveViewer(child: Image.network(url))),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onImageTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        // AI messages are styled slightly differently
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : (message.senderId == 'ai'
                    ? Colors.blueGrey[50]
                    : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.deleted)
              Text(
                message.text.isNotEmpty ? message.text : 'Message deleted',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              )
            else ...[
              if (message.senderId == 'ai')
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              if (message.imageUrl != null)
                GestureDetector(
                  onTap: onImageTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                        (progress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                ),
              if (message.edited)
                Text(
                  'edited',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
