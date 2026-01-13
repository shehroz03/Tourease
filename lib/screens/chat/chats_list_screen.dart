import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/tour_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  Stream<List<ChatModel>>? _chatsStream;
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final chatService = ChatService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Initialize or update stream if user changes
    if (_chatsStream == null || _lastUserId != user.id) {
      _chatsStream = chatService.streamUserChats(user.id, user.role.name);
      _lastUserId = user.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            String errorMessage = 'Failed to load chats';
            if (error.contains('failed-precondition') ||
                error.contains('index')) {
              errorMessage =
                  'Please create the required Firestore index. Check the console for the index creation URL.';
            } else if (error.contains('permission-denied')) {
              errorMessage = 'You do not have permission to view chats.';
            } else if (error.contains('unavailable')) {
              errorMessage =
                  'Service temporarily unavailable. Please try again later.';
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The stream will retry automatically',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.role == UserRole.traveler
                        ? 'Start a chat from a tour page'
                        : 'Travelers will contact you here',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatTile(chat: chat, currentUser: user);
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final UserModel currentUser;

  const _ChatTile({required this.chat, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final tourService = TourService();
    final otherUserId =
        (currentUser.role == UserRole.traveler ||
            currentUser.role == UserRole.admin)
        ? chat.agencyId
        : chat.travelerId;

    return FutureBuilder<UserModel?>(
      future: authService.getUserById(otherUserId),
      builder: (context, userSnapshot) {
        return FutureBuilder(
          future: tourService.getTourById(chat.tourId),
          builder: (context, tourSnapshot) {
            final otherUser = userSnapshot.data;
            final tour = tourSnapshot.data;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  otherUser?.name.isNotEmpty == true
                      ? otherUser!.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                otherUser?.name ?? 'Loading...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tour != null)
                    Text(
                      'Re: ${tour.title}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  if (chat.lastMessage != null)
                    Text(
                      chat.lastMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Text(
                _formatTime(chat.updatedAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () => context.push('/chat/${chat.id}'),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }
}
