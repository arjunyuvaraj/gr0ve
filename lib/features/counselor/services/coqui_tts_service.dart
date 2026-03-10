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

// Coqui XTTS v2 voice mappings (using available default speaker clones or placeholder labels)
const _voiceConfigs = {
  CounselorPersona.grover: 'Craig Daniels', // Male
  CounselorPersona.aspen: 'Ana Florence', // Female
  CounselorPersona.rowan: 'Royston Min', // Male deep
  CounselorPersona.sakura: 'Claribel Dervla', // Female
  CounselorPersona.abies: 'Tammie Ema', // Male wise
  CounselorPersona.cedite: 'Daisy Studious', // Female
  CounselorPersona.ash: 'Baldur Sanjin', // Male neutral
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

class CoquiTTSService {
  CoquiTTSService._();

  static AudioPlayer? _player;
  static bool _stopRequested = false;
  static bool _initialized = false;
  static StreamSubscription? _stateSubscription;

  // Assuming an API base URL (e.g., hosted Hugging Face API or local server)
  static String get _apiUrl {
    // Android emulator maps the host machine to 10.0.2.2 instead of localhost
    if (Platform.isAndroid) {
      return dotenv.env['COQUI_API_URL']?.replaceAll('localhost', '10.0.2.2') ??
          'http://10.0.2.2:8020/xtts/tts';
    }
    return dotenv.env['COQUI_API_URL'] ?? 'http://localhost:8020/xtts/tts';
  }

  static bool get isPlaying {
    final p = _player;
    return p != null && p.playing;
  }

  /// Initialize Coqui TTS service
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      debugPrint('[CoquiTTS] Initializing...');

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
      debugPrint('[CoquiTTS] ✓ Initialized');
      return true;
    } catch (e) {
      debugPrint('[CoquiTTS] ❌ Initialization failed: $e');
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
      debugPrint('[CoquiTTS] Not initialized, calling onDone immediately');
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
    final speaker =
        _voiceConfigs[persona] ?? _voiceConfigs[CounselorPersona.grover]!;

    debugPrint(
      '[CoquiTTS] speak() START: "${withFiller.substring(0, withFiller.length > 60 ? 60 : withFiller.length)}..."',
    );

    try {
      debugPrint('[CoquiTTS] Synthesizing via Coqui XTTS v2 ($speaker)...');
      final wavBytes = await _synthesize(withFiller, speaker);

      if (_stopRequested || wavBytes == null) {
        debugPrint(
          '[CoquiTTS] Aborted (stopped=$_stopRequested, null=${wavBytes == null})',
        );
        onDone();
        return;
      }

      debugPrint('[CoquiTTS] Got ${wavBytes.length} WAV bytes');

      final player = _player!;
      bool onReadyCalled = false;
      bool onDoneCalled = false;

      void callOnDone() {
        if (!onDoneCalled) {
          onDoneCalled = true;
          _stateSubscription?.cancel();
          _stateSubscription = null;
          debugPrint('[CoquiTTS] ✓ onDone called');
          onDone();
        }
      }

      // Cancel old state listener
      _stateSubscription?.cancel();

      // Listen to player state
      _stateSubscription = player.playerStateStream.listen((state) {
        if (state.playing && !onReadyCalled) {
          onReadyCalled = true;
          debugPrint('[CoquiTTS] ✓ Audio started playing, calling onReady');
          onReady?.call();
        }
      });

      // Write WAV to a temp file
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/coqui_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await file.writeAsBytes(wavBytes, flush: true);

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

      // Load WAV directly from file
      debugPrint('[CoquiTTS] Loading WAV from file: ${file.path}...');
      await player.setFilePath(file.path);

      if (_stopRequested) {
        callOnDone();
        return;
      }

      debugPrint('[CoquiTTS] Calling play()...');
      await player.play();
      debugPrint('[CoquiTTS] ✓ play() returned naturally (audio finished)');

      if (!onDoneCalled) {
        callOnDone();
      }
    } catch (e, stack) {
      debugPrint('[CoquiTTS] ❌ Exception: $e');
      debugPrint(stack.toString());
      onDone();
    }
  }

  static Future<void> stop() async {
    debugPrint('[CoquiTTS] stop() called');
    _stopRequested = true;
    await _stopPlayer();
  }

  static Future<void> dispose() async {
    debugPrint('[CoquiTTS] dispose() called');
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
      debugPrint('[CoquiTTS] Player stopped');
    }
  }

  /// Synthesize audio using Coqui API — returns WAV
  static Future<Uint8List?> _synthesize(
    String text,
    String speaker,
  ) async {
    try {
      final uri = Uri.parse(_apiUrl);

      final bodyJson = jsonEncode({
        'text': text,
        'language': 'en',
        'speaker_wav': speaker,
      });
      final bodyBytes = Utf8Encoder().convert(bodyJson);

      final response = await http
          .post(uri, headers: {
        'Content-Type': 'application/json',
      }, body: bodyBytes)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        debugPrint(
            '[CoquiTTS] ✓ Synthesized ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      }

      debugPrint(
        '[CoquiTTS] ❌ API error ${response.statusCode}: ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('[CoquiTTS] ❌ Synthesis exception: $e');
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
