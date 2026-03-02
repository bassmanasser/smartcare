import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // ✅ مكتبة Gemini
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // لتنسيق النص

import '../../models/patient.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';

class AiBotScreen extends StatefulWidget {
  final Patient patient;
  const AiBotScreen({super.key, required this.patient});

  @override
  State<AiBotScreen> createState() => _AiBotScreenState();
}

class _AiBotScreenState extends State<AiBotScreen> {
  // 🔑 ضعي مفتاح API الخاص بك هنا
  // احصلي عليه من: https://aistudio.google.com/app/apikey
  final String _apiKey = 'AIzaSyA0H_MF2QgqmZKrPpKBksI0Dk71c4QXh_o'; 

  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  
  final List<ChatMessage> _messages = []; // لتخزين الرسائل في الواجهة
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // إعداد نموذج Gemini
// ✅ ده الموديل الأسرع والأحدث حالياً
   _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    _chat = _model.startChat();
    
    // رسالة ترحيبية تلقائية
    _addMessage("Hello ${widget.patient.name}! I am your health assistant. I can see your latest vitals. How can I help you today?", false);
  }

  // دالة لإضافة رسالة للشاشة
  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    // النزول لآخر المحادثة
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  // دالة إرسال الرسالة
  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    _addMessage(text, true); // عرض رسالة المستخدم
    setState(() => _loading = true);

    try {
      // 1. تجهيز السياق (Context) من بيانات المريض الحالية
      final appState = Provider.of<AppState>(context, listen: false);
      final lastVital = appState.vitals.isNotEmpty ? appState.vitals.last : null;
      
      String contextInfo = "You are a helpful medical assistant for a patient named ${widget.patient.name}. ";
      if (lastVital != null) {
        contextInfo += "Current Vitals -> Heart Rate: ${lastVital.hr}, SpO2: ${lastVital.spo2}%, "
            "Glucose: ${lastVital.glucose}, BP: ${lastVital.sys}/${lastVital.dia}, Temp: ${lastVital.temperature}. ";
      }
      contextInfo += "User asks: $text";

      // 2. إرسال للذكاء الاصطناعي
      final response = await _chat.sendMessage(Content.text(contextInfo));
      final reply = response.text;

      if (reply != null) {
        _addMessage(reply, false);
      } else {
        _addMessage("Sorry, I couldn't understand that.", false);
      }

    } catch (e) {
      // ✅ ده هيطبع الخطأ بالتفصيل في الـ Run Console تحت
      debugPrint("❌ Gemini Error: $e"); 
      
      _addMessage("Error: Check internet or API Key.", false);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Health Assistant"),
        backgroundColor: PETROL_DARK,
      ),
      body: Column(
        children: [
          // قائمة الرسائل
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.isUser ? PETROL : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: msg.isUser ? const Radius.circular(12) : Radius.zero,
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: msg.isUser 
                      ? Text(msg.text, style: const TextStyle(color: Colors.white))
                      : MarkdownBody(data: msg.text), // استخدام Markdown لتنسيق رد البوت
                  ),
                );
              },
            ),
          ),

          // مؤشر التحميل
          if (_loading) const LinearProgressIndicator(color: PETROL),

          // حقل الإدخال
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: InputDecoration(
                      hintText: "Ask about your health...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _loading ? null : _sendMessage,
                  backgroundColor: PETROL,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// موديل بسيط للرسالة داخل الشاشة فقط
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}