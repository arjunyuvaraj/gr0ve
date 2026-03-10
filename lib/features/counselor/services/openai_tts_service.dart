import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_session/audio_session.dart' as session;
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────
// VOICE CONFIG
// ─────────────────────────────────────────────────────────────

// OpenAI TTS voice mappings for each persona
const _voiceConfigs = {
  CounselorPersona.grover: 'echo',     // Male, warm and fairly natural
  CounselorPersona.aspen: 'nova',      // Female, expressive and warm
  CounselorPersona.rowan: 'onyx',      // Male, deep and commanding
  CounselorPersona.sakura: 'shimmer',  // Female, clear and calming
  CounselorPersona.abies: 'onyx',      // Male, deep and wise
  CounselorPersona.cedite: 'nova',     // Female, expressive American
  CounselorPersona.ash: 'alloy',       // Neutral, versatile
};

// ─────────────────────────────────────────────────────────────
// FILLER WORDS
// ─────────────────────────────────────────────────────────────

const _fillers = {
  CounselorPersona.grover: [
    'Yeah, so — ',
    'Hmm. ',
    'Okay, so — ',
    'Right — ',
    'Good question. ',
  ],
  CounselorPersona.aspen: [
    'Oh, okay — ',
    'Hmm, let me think... ',
    'Yeah — ',
    'So — ',
    'Interesting. ',
  ],
  CounselorPersona.rowan: [
    'Right — ',
    'Look, so — ',
    'Yeah, honestly — ',
    'Okay — ',
    'Fair enough. ',
  ],
  CounselorPersona.sakura: [
    'Hmm — ',
    'Oh! Okay so — ',
    'Right, so — ',
    'Yeah — ',
    'Let me think... ',
  ],
  CounselorPersona.abies: [
    'Okay — ',
    'So — ',
    'Yeah, so — ',
    'Hmm. ',
    'Right — ',
  ],
  CounselorPersona.cedite: [
    'Alright, so — ',
    'Yes — ',
    'Hmm. ',
    'Okay — ',
    'Right, so — ',
  ],
  CounselorPersona.ash: ['Yeah — ', 'Hmm. ', 'Okay so — ', 'Right — ', 'So — '],
};

String _withFiller(String text, CounselorPersona persona) {
  final list = _fillers[persona] ?? _fillers[CounselorPersona.grover]!;
  final filler =
      list[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % list.length];
  return '$filler$text';
}

// ─────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────

class OpenAITTSService {
  OpenAITTSService._();

  static AudioPlayer? _player;
  static bool _stopRequested = false;
  static bool _initialized = false;
  static StreamSubscription? _stateSubscription;

  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static bool get isPlaying {
    final p = _player;
    return p != null && p.playing;
  }

  /// Initialize OpenAI TTS service
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      debugPrint('[OpenAITTS] Initializing...');
      if (_apiKey.isEmpty) {
        debugPrint('[OpenAITTS] ❌ Missing OPENAI_API_KEY in .env');
        return false;
      }

      // Configure Audio Session immediately (fixes iOS -11800 error from STT conflicts)
      final sessionInstance = await session.AudioSession.instance;
      await sessionInstance.configure(
        session.AudioSessionConfiguration(
          avAudioSessionCategory: session.AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              session.AVAudioSessionCategoryOptions.mixWithOthers |
              session.AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: session.AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions:
              session.AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: session.AndroidAudioAttributes(
            contentType: session.AndroidAudioContentType.speech,
            flags: session.AndroidAudioFlags.none,
            usage: session.AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType:
              session.AndroidAudioFocusGainType.gainTransientExclusive,
          androidWillPauseWhenDucked: true,
        ),
      );

      _player = AudioPlayer();
      _initialized = true;
      debugPrint('[OpenAITTS] ✓ Initialized');
      return true;
    } catch (e) {
      debugPrint('[OpenAITTS] ❌ Initialization failed: $e');
      return false;
    }
  }

  /// Speaks [text] with the given [persona]'s voice.
  static Future<void> speak({
    required String text,
    required CounselorPersona persona,
    required VoidCallback onDone,
    VoidCallback? onReady,
    bool isGreeting = false,
  }) async {
    if (!_initialized || _player == null) {
      debugPrint('[OpenAITTS] Not initialized, calling onDone immediately');
      onDone();
      return;
    }

    await _stopPlayer();
    _stopRequested = false;

    final cleaned = _stripMarkdown(text);
    if (cleaned.isEmpty) {
      onDone();
      return;
    }

    final withFiller = isGreeting ? cleaned : _withFiller(cleaned, persona);
    final voiceId =
        _voiceConfigs[persona] ?? _voiceConfigs[CounselorPersona.grover]!;

    debugPrint(
      '[OpenAITTS] speak() START: "${withFiller.substring(0, withFiller.length > 60 ? 60 : withFiller.length)}..."',
    );

    try {
      debugPrint('[OpenAITTS] Synthesizing via OpenAI ($voiceId)...');
      final mp3Bytes = await _synthesize(withFiller, voiceId);

      if (_stopRequested || mp3Bytes == null) {
        debugPrint(
          '[OpenAITTS] Aborted (stopped=$_stopRequested, null=${mp3Bytes == null})',
        );
        onDone();
        return;
      }

      debugPrint('[OpenAITTS] Got ${mp3Bytes.length} MP3 bytes');

      final player = _player!;
      bool onReadyCalled = false;
      bool onDoneCalled = false;

      void callOnDone() {
        if (!onDoneCalled) {
          onDoneCalled = true;
          _stateSubscription?.cancel();
          _stateSubscription = null;
          debugPrint('[OpenAITTS] ✓ onDone called');
          onDone();
        }
      }

      // Cancel old state listener
      _stateSubscription?.cancel();

      // Listen to player state
      _stateSubscription = player.playerStateStream.listen((state) {
        if (state.playing && !onReadyCalled) {
          onReadyCalled = true;
          debugPrint('[OpenAITTS] ✓ Audio started playing, calling onReady');
          onReady?.call();
        }
      });

      // Write MP3 to a temp file
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/openai_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await file.writeAsBytes(mp3Bytes, flush: true);

      // Reset AudioSession to playback to override STT
      final sessionInstance = await session.AudioSession.instance;
      await sessionInstance.configure(
        session.AudioSessionConfiguration(
          avAudioSessionCategory: session.AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              session.AVAudioSessionCategoryOptions.mixWithOthers |
              session.AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: session.AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions:
              session.AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: session.AndroidAudioAttributes(
            contentType: session.AndroidAudioContentType.speech,
            flags: session.AndroidAudioFlags.none,
            usage: session.AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType:
              session.AndroidAudioFocusGainType.gainTransientExclusive,
          androidWillPauseWhenDucked: true,
        ),
      );

      // Load MP3 directly from file
      debugPrint('[OpenAITTS] Loading MP3 from file: ${file.path}...');
      await player.setFilePath(file.path);

      if (_stopRequested) {
        callOnDone();
        return;
      }

      debugPrint('[OpenAITTS] Calling play()...');
      await player.play();
      debugPrint('[OpenAITTS] ✓ play() returned naturally (audio finished)');

      if (!onDoneCalled) {
        callOnDone();
      }
    } catch (e, stack) {
      debugPrint('[OpenAITTS] ❌ Exception: $e');
      debugPrint(stack.toString());
      onDone();
    }
  }

  static Future<void> stop() async {
    debugPrint('[OpenAITTS] stop() called');
    _stopRequested = true;
    await _stopPlayer();
  }

  static Future<void> dispose() async {
    debugPrint('[OpenAITTS] dispose() called');
    _stopRequested = true;
    _stateSubscription?.cancel();
    _stateSubscription = null;
    final p = _player;
    _player = null;
    if (p != null) {
      try {
        await p.stop();
      } catch (_) {}
      try {
        await p.dispose();
      } catch (_) {}
    }
    _initialized = false;
  }

  /// Stop playback without disposing the player
  static Future<void> _stopPlayer() async {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    final p = _player;
    if (p != null) {
      try {
        await p.stop();
        await p.seek(Duration.zero);
      } catch (_) {}
      debugPrint('[OpenAITTS] Player stopped');
    }
  }

  /// Synthesize audio using OpenAI TTS — returns MP3
  static Future<Uint8List?> _synthesize(
    String text,
    String voiceId,
  ) async {
    try {
      final uri = Uri.parse('https://api.openai.com/v1/audio/speech');

      final bodyJson = jsonEncode({
        'model': 'tts-1',
        'input': text,
        'voice': voiceId,
        'response_format': 'mp3',
      });
      final bodyBytes = Utf8Encoder().convert(bodyJson);

      final response = await http
          .post(uri, headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }, body: bodyBytes)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('[OpenAITTS] ✓ Synthesized ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      }

      debugPrint(
        '[OpenAITTS] ❌ API error ${response.statusCode}: ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('[OpenAITTS] ❌ Synthesis exception: $e');
      return null;
    }
  }

  static String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'>\s'), '')
        .trim();
  }
}
