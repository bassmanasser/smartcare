import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/auth_service.dart';
import '../../services/phia_service.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  String _state = 'idle';
  String _recognized = '';
  String _answer = '';

  List<String> _alerts = [];

  bool _sttReady = false;

  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _pulse,
        curve: Curves.easeInOut,
      ),
    );

    _initSTT();
    _initTTS();
  }

  Future<void> _initSTT() async {
    _sttReady = await _stt.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') &&
            _state == 'listening') {

          if (_recognized.isNotEmpty) {
            _askAgent(_recognized);
          } else {
            setState(() => _state = 'idle');
          }
        }
      },
      onError: (_) {
        setState(() {
          _state = 'idle';
          _recognized = '';
        });
      },
    );
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('ar-EG');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _state = 'idle');
      }
    });
  }

  Future<void> _onTap() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showLoginRequired();
      return;
    }

    if (_state == 'idle') {

      if (!_sttReady) {
        _snack('الميكروفون غير متاح حالياً');
        return;
      }

      setState(() {
        _state = 'listening';
        _recognized = '';
        _answer = '';
      });

      await _stt.listen(
        onResult: (r) {
          setState(() {
            _recognized = r.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: 'ar_EG',
      );

    } else if (_state == 'listening') {

      await _stt.stop();

      if (_recognized.isNotEmpty) {
        await _askAgent(_recognized);
      } else {
        setState(() => _state = 'idle');
      }

    } else if (_state == 'speaking') {

      await _tts.stop();

      setState(() => _state = 'idle');
    }
  }

  Future<void> _askAgent(String q) async {

    setState(() {
      _state = 'thinking';
      _recognized = q;
    });

    await _stt.stop();

    try {

      final res = await PHIAService.ask(q);

      final ans = res['answer'] as String;

      final alr = List<String>.from(
        res['alerts'] as List,
      );

      setState(() {
        _answer = ans;
        _alerts = alr;
        _state = 'speaking';
      });

      if (alr.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تنبيه: ${alr.first}',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 6),
          ),
        );
      }

      await _tts.speak(_clean(ans));

    } catch (e) {

      debugPrint('PHIA ERROR: $e');

      setState(() {
        _state = 'idle';
        _answer = 'حدث خطأ. تحقق من الاتصال.';
        _alerts = [];
      });

      _snack('حدث خطأ أثناء الاتصال بالخادم');
    }
  }

  String _clean(String t) {
    return t
        .replaceAll(
          RegExp(r'\*+([^*]+)\*+'),
          r'$1',
        )
        .replaceAll(
          RegExp(
            r'^#{1,6}\s+',
            multiLine: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'^\s*[-•]\s+',
            multiLine: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'[━=─]{3,}'),
          '',
        )
        .trim();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          m,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _showLoginRequired() {

    _stt.stop();
    _tts.stop();

    if (!mounted) return;

    setState(() {
      _state = 'idle';
      _answer = 'Please log in first.';
      _alerts = [];
    });

    _snack('Please log in first.');
  }

  Color get _color =>
      const {
        'listening': Colors.red,
        'thinking': Colors.orange,
        'speaking': Colors.teal,
      }[_state] ??
      Colors.teal;

  IconData get _icon =>
      const {
        'listening': Icons.mic,
        'thinking': Icons.hourglass_top,
        'speaking': Icons.volume_up,
      }[_state] ??
      Icons.mic_none;

  @override
  void dispose() {
    _pulse.dispose();
    _stt.stop();
    _tts.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final auth = Provider.of<AuthService>(
      context,
      listen: false,
    );

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null) {

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Voice Assistant',
              ),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text(
                'Please log in first.',
              ),
            ),
          );
        }

        return _buildVoiceUi(context);
      },
    );
  }

  Widget _buildVoiceUi(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment:
              MainAxisAlignment.end,
          children: [
            Text('المساعد الصوتي'),
            SizedBox(width: 8),
            Icon(Icons.mic, size: 20),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [

            const SizedBox(height: 40),

            Icon(
              Icons.health_and_safety,
              size: 56,
              color: Colors.teal[600],
            ),

            const SizedBox(height: 8),

            Text(
              'مساعد PHIA الذكي',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),

            const Spacer(),

            if (_answer.isNotEmpty &&
                _state != 'listening')
              Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.teal[100]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _answer,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

            const Spacer(),

            Text(
              _state == 'listening'
                  ? (_recognized.isEmpty
                      ? 'جاري الاستماع...'
                      : '"$_recognized"')
                  : _state == 'thinking'
                      ? 'جاري تحليل بياناتك...'
                      : _state == 'speaking'
                          ? 'جاري نطق الإجابة...'
                          : 'اضغط على الميكروفون للتحدث',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _state == 'idle'
                    ? Colors.grey
                    : _color,
              ),
            ),

            const SizedBox(height: 32),

            AnimatedBuilder(
              animation: _scale,
              builder: (_, __) {
                return Transform.scale(
                  scale: _state == 'listening'
                      ? _scale.value
                      : 1.0,
                  child: GestureDetector(
                    onTap: _onTap,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _color,
                        boxShadow: [
                          BoxShadow(
                            color: _color.withOpacity(
                              0.4,
                            ),
                            blurRadius: 20,
                            spreadRadius:
                                _state ==
                                        'listening'
                                    ? 8
                                    : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _icon,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            Text(
              _state == 'listening'
                  ? 'اضغط للإرسال'
                  : _state == 'speaking'
                      ? 'اضغط للإيقاف'
                      : _state == 'thinking'
                          ? 'يرجى الانتظار...'
                          : 'اضغط للبدء',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}