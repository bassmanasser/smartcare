import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/ai_message.dart';
import '../../services/ai_bot_service.dart';
import '../../utils/constants.dart';

class AiBotScreen extends StatefulWidget {
  final Patient patient;
  const AiBotScreen({super.key, required this.patient});

  @override
  State<AiBotScreen> createState() => _AiBotScreenState();
}

class _AiBotScreenState extends State<AiBotScreen> {
  final _service = AiBotService();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<AiMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _service.loadHistory(widget.patient.id);
    setState(() => _messages = history);
  }

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(AiMessage(
        role: 'user',
        content: text,
        timestamp: DateTime.now(),
      ));
      _loading = true;
    });

    _scrollDown();

    final aiMsg = await _service.sendMessage(
      patientId: widget.patient.id,
      message: text,
    );

    setState(() {
      _messages.add(aiMsg);
      _loading = false;
    });

    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCare AI'),
        backgroundColor: PETROL_DARK,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (c, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints:
                        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? PETROL : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask SmartCare AI...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: PETROL),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
