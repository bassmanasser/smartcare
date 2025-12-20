import 'package:flutter/material.dart';

// هذا هو كلاس البيانات الخاص بالرسالة
class ChatMessage {
  final String role;
  final String text;
  const ChatMessage({required this.role, required this.text});
}

// هذا هو الويدجت الخاص بشكل الرسالة
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatMessageBubble({super.key, required this.message});
  
  get PETROL_ACC => null;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? PETROL_ACC.withOpacity(0.3) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}