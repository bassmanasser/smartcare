import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class ConversationsScreen extends StatelessWidget {
  final String currentUserId;
  final String currentRole; // 'patient' / 'doctor' / 'parent'

  const ConversationsScreen({
    super.key,
    required this.currentUserId,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: PETROL_DARK,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No conversations yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final participants = (data['participants'] as List?)?.cast<String>() ?? <String>[];
              final others = participants.where((x) => x != currentUserId).toList();
              final otherId = others.isNotEmpty ? others.first : 'unknown';

              final participantNames = (data['participantNames'] as Map?)?.cast<String, dynamic>();
              final participantRoles = (data['participantRoles'] as Map?)?.cast<String, dynamic>();

              final otherName = participantNames != null && participantNames[otherId] != null
                  ? participantNames[otherId].toString()
                  : 'User';

              final otherRole = participantRoles != null && participantRoles[otherId] != null
                  ? participantRoles[otherId].toString()
                  : '';

              final lastMsg = (data['lastMessage'] ?? '').toString();
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: PETROL.withOpacity(0.15),
                    child: Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: PETROL_DARK),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (updatedAt != null)
                        Text(
                          _formatTime(updatedAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (otherRole.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            otherRole.toUpperCase(),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        lastMsg.isEmpty ? 'Say hi 👋' : lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          conversationId: d.id,
                          currentUserId: currentUserId,
                          currentRole: currentRole,
                          peerUserId: otherId,
                          peerName: otherName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------
// Chat Room (Messages)
// ---------------------------

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String currentRole;

  final String peerUserId;
  final String peerName;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.currentRole,
    required this.peerUserId,
    required this.peerName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  CollectionReference<Map<String, dynamic>> get _msgCol =>
      FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).collection('messages');

  DocumentReference<Map<String, dynamic>> get _convDoc =>
      FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId);

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      final now = Timestamp.now();

      // 1) add message
      await _msgCol.add({
        'senderId': widget.currentUserId,
        'senderRole': widget.currentRole,
        'text': text,
        'createdAt': now,
      });

      // 2) update conversation metadata
      await _convDoc.set({
        'lastMessage': text,
        'lastSenderId': widget.currentUserId,
        'updatedAt': now,
      }, SetOptions(merge: true));

      // scroll down (newest at bottom because we reverse list)
      await Future.delayed(const Duration(milliseconds: 120));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _msgCol.orderBy('createdAt', descending: true).limit(200);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName, overflow: TextOverflow.ellipsis),
            Text(
              'Chat',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: q.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final senderId = (m['senderId'] ?? '').toString();
                    final text = (m['text'] ?? '').toString();
                    final ts = (m['createdAt'] as Timestamp?)?.toDate();

                    final isMe = senderId == widget.currentUserId;

                    return _ChatBubble(
                      isMe: isMe,
                      text: text,
                      time: ts != null ? _formatMsgTime(ts) : '',
                    );
                  },
                );
              },
            ),
          ),

          // input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: LIGHT_BG,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sending ? null : _send,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _sending ? Colors.grey : PETROL,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
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

  static String _formatMsgTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;

  const _ChatBubble({
    required this.isMe,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? PETROL : Colors.white;
    final fg = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: fg, fontSize: 14, height: 1.25),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.75) : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
