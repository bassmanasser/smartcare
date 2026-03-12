import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../models/vital_sample.dart';
import '../../providers/app_state.dart';
import '../../services/ai_chat_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

class AiBotScreen extends StatefulWidget {
  final Patient patient;
  const AiBotScreen({super.key, required this.patient});

  @override
  State<AiBotScreen> createState() => _AiBotScreenState();
}

class _AiBotScreenState extends State<AiBotScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = AppLocalizations.of(context);
      final isArabic =
          Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

      _addMessage(
        isArabic
            ? 'مرحبًا ${widget.patient.name}، أنا المساعد الصحي في SmartCare. أقدر أشرح لك القراءات وأساعدك بنصائح آمنة وبسيطة.'
            : 'Hello ${widget.patient.name}, I am your SmartCare health assistant. I can explain readings and provide simple safe guidance.',
        false,
      );
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Map<String, dynamic>? _latestVitalsMap(AppState appState) {
    final VitalSample? lastVital = appState.getLatestVitals(widget.patient.id);
    if (lastVital == null) return null;

    return {
      'hr': lastVital.hr,
      'spo2': lastVital.spo2,
      'sys': lastVital.sys,
      'dia': lastVital.dia,
      'glucose': lastVital.glucose,
      'temperature': lastVital.temperature,
      'fallFlag': lastVital.fallFlag,
      'timestamp': lastVital.timestamp.toIso8601String(),
    };
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final languageCode = Localizations.localeOf(context).languageCode;

    _textCtrl.clear();
    _addMessage(text, true);
    setState(() => _loading = true);

    try {
      final reply = await AiChatService.sendMessage(
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        message: text,
        languageCode: languageCode,
        latestVitals: _latestVitalsMap(appState),
      );

      _addMessage(reply, false);
    } catch (e) {
      final isArabic = languageCode == 'ar';
      _addMessage(
        isArabic
            ? 'حدث خطأ أثناء الاتصال بالمساعد الذكي. تأكدي من الإنترنت أو السيرفر.'
            : 'There was an error connecting to the AI assistant. Check internet or backend.',
        false,
      );
      debugPrint('❌ AI Chat Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(lang.translate('ai_bot')),
        backgroundColor: PETROL_DARK,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      lang.translate('start_chatting'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];

                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isUser ? PETROL : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: msg.isUser
                                  ? const Radius.circular(14)
                                  : Radius.zero,
                              bottomRight: msg.isUser
                                  ? Radius.zero
                                  : const Radius.circular(14),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: msg.isUser
                              ? Text(
                                  msg.text,
                                  style: const TextStyle(color: Colors.white),
                                )
                              : MarkdownBody(
                                  data: msg.text,
                                  selectable: true,
                                ),
                        ),
                      );
                    },
                  ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: LinearProgressIndicator(color: PETROL),
            ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: lang.translate('ask_about_your_health'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}