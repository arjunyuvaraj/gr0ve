import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart' as session;
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:http/http.dart' as http;

class _PollyVoiceConfig {
  final String voiceId;
  final String engine;

  const _PollyVoiceConfig({required this.voiceId, this.engine = 'generative'});
}

const _voiceConfigs = {
  CounselorPersona.grover: _PollyVoiceConfig(
    voiceId: 'Stephen',
    engine: 'neural',
  ),
  CounselorPersona.aspen: _PollyVoiceConfig(voiceId: 'Ruth', engine: 'neural'),
  CounselorPersona.rowan: _PollyVoiceConfig(
    voiceId: 'Matthew',
    engine: 'neural',
  ),
  CounselorPersona.sakura: _PollyVoiceConfig(voiceId: 'Ruth', engine: 'neural'),
  CounselorPersona.abies: _PollyVoiceConfig(
    voiceId: 'Matthew',
    engine: 'neural',
  ),
  CounselorPersona.cedite: _PollyVoiceConfig(
    voiceId: 'Gregory',
    engine: 'generative',
  ),
  CounselorPersona.ash: _PollyVoiceConfig(
    voiceId: 'Danielle',
    engine: 'neural',
  ),
};

const _fillerWords = {
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
    'Yeah, — ',
    'Honestly? ',
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
    'Or so you think — ',
    'A curious perspective... ',
    'Perhaps. ',
    'The truth is... well — ',
    'Fascinating. ',
  ],
  CounselorPersona.ash: [
    'I remember — ',
    'It feels so long ago — ',
    'The silence... ',
    'It\'s all so fragile — ',
    'Before it all fades — ',
  ],
};

String _addFiller(String text, CounselorPersona persona) {
  final fillers =
      _fillerWords[persona] ?? _fillerWords[CounselorPersona.grover]!;
  final index =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) % fillers.length;
  return '${fillers[index]}$text';
}

class _AwsV4Signer {
  final String accessKey;
  final String secretKey;
  final String region;
  final String service;

  _AwsV4Signer({
    required this.accessKey,
    required this.secretKey,
    required this.region,
  }) : service = 'polly';

  Map<String, String> sign({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Uint8List body,
    required DateTime dateTime,
  }) {
    final dateStamp = _formatDate(dateTime);
    final amzDate = _formatAmzDate(dateTime);
    final credentialScope = '$dateStamp/$region/$service/aws4_request';

    final signedHeaders = <String, String>{
      ...headers,
      'host': uri.host,
      'x-amz-date': amzDate,
    };

    final sortedHeaderKeys = _sortedHeaderKeys(signedHeaders);
    final canonicalHeaders = _canonicalHeaders(signedHeaders, sortedHeaderKeys);
    final signedHeaderStr = sortedHeaderKeys.join(';');
    final payloadHash = sha256.convert(body).toString();

    final canonicalRequest = [
      method,
      uri.path,
      uri.query,
      '$canonicalHeaders\n',
      signedHeaderStr,
      payloadHash,
    ].join('\n');

    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, service);
    final kSigning = _hmacSha256(kService, 'aws4_request');

    final signature = Hmac(
      sha256,
      kSigning,
    ).convert(utf8.encode(stringToSign)).toString();

    final authHeader =
        'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeaderStr, Signature=$signature';

    return {
      ...signedHeaders,
      'authorization': authHeader,
      'x-amz-content-sha256': payloadHash,
    };
  }

  List<int> _hmacSha256(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  String _formatDate(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _formatAmzDate(DateTime dt) =>
      '${_formatDate(dt)}T${dt.hour.toString().padLeft(2, '0')}'
      '${dt.minute.toString().padLeft(2, '0')}'
      '${dt.second.toString().padLeft(2, '0')}Z';

  List<String> _sortedHeaderKeys(Map<String, String> headers) =>
      (headers.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())));

  String _canonicalHeaders(
    Map<String, String> headers,
    List<String> sortedKeys,
  ) => sortedKeys
      .map((k) => '${k.toLowerCase()}:${headers[k]!.trim()}')
      .join('\n');
}

class PollyService {
  PollyService._();

  static AudioPlayer? _player;
  static bool _stopRequested = false;
  static bool _initialized = false;
  static StreamSubscription? _stateSubscription;
  static final StreamController<void> _playbackCompletedController =
      StreamController<void>.broadcast();

  static String get _accessKey => dotenv.env['AWS_ACCESS_KEY_ID'] ?? '';
  static String get _secretKey => dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '';
  static String get _region => dotenv.env['AWS_REGION'] ?? 'us-east-1';

  static bool get isPlaying => _player?.playing ?? false;

  static bool get isInitialized => _initialized;

  static Stream<void> get onPlaybackCompleted =>
      _playbackCompletedController.stream;

  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      debugPrint('[Polly] Initializing...');

      if (_accessKey.isEmpty || _secretKey.isEmpty) {
        debugPrint('[Polly] ❌ Missing AWS credentials in .env');
        return false;
      }

      await _setupPlaybackAudioSession();

      _player = AudioPlayer();
      _initialized = true;
      debugPrint('[Polly] ✓ Initialized (region: $_region)');
      return true;
    } catch (e) {
      debugPrint('[Polly] ❌ Initialization failed: $e');
      return false;
    }
  }

  static Future<void> dispose() async {
    debugPrint('[Polly] Disposing...');
    _stopRequested = true;

    await _stateSubscription?.cancel();
    _stateSubscription = null;

    final p = _player;
    _player = null;

    if (p != null) {
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }

    await _playbackCompletedController.close();
    _initialized = false;
  }

  static Future<void> speak({
    required String text,
    required CounselorPersona persona,
    required VoidCallback onDone,
    VoidCallback? onReady,
    bool isGreeting = false,
  }) async {
    if (!_initialized || _player == null) {
      debugPrint('[Polly] Not initialized');
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

    final withFiller = isGreeting ? cleaned : _addFiller(cleaned, persona);
    final config =
        _voiceConfigs[persona] ?? _voiceConfigs[CounselorPersona.grover]!;

    debugPrint('[Polly] Speaking: "${_truncate(withFiller, 60)}..."');

    try {
      final mp3Bytes = await _synthesizeAudio(withFiller, config);

      if (_stopRequested || mp3Bytes == null) {
        onDone();
        return;
      }

      await _playAudio(mp3Bytes, onReady, onDone);
    } catch (e) {
      debugPrint('[Polly] ❌ Exception: $e');
      onDone();
    }
  }

  static Future<void> stopAndPrepareForListening() async {
    debugPrint('[Polly] Stopping and preparing for listening...');
    _stopRequested = true;
    await _stopPlayer();

    await _configureRecordingAudioSession();

    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('[Polly] ✓ Ready for STT');
  }

  static Future<void> stop() async {
    debugPrint('[Polly] Stopping...');
    _stopRequested = true;
    await _stopPlayer();
  }

  static Future<void> _setupPlaybackAudioSession() async {
    try {
      debugPrint('[Polly] Configuring AudioSession for playback...');
      final sessionInstance = await session.AudioSession.instance;
      await sessionInstance.configure(
        session.AudioSessionConfiguration(
          avAudioSessionCategory: session.AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              session.AVAudioSessionCategoryOptions.defaultToSpeaker,
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
      debugPrint('[Polly] ✓ Playback session configured');
    } catch (e) {
      debugPrint('[Polly] ⚠ Playback session config failed: $e');
    }
  }

  static Future<void> _configureRecordingAudioSession() async {
    try {
      debugPrint('[Polly] Configuring AudioSession for recording...');
      final sessionInstance = await session.AudioSession.instance;
      await sessionInstance.configure(
        session.AudioSessionConfiguration(
          avAudioSessionCategory: session.AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              session.AVAudioSessionCategoryOptions.defaultToSpeaker |
              session.AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: session.AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions:
              session.AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: session.AndroidAudioAttributes(
            contentType: session.AndroidAudioContentType.speech,
            flags: session.AndroidAudioFlags.none,
          ),
          androidAudioFocusGainType:
              session.AndroidAudioFocusGainType.gainTransientExclusive,
          androidWillPauseWhenDucked: false,
        ),
      );
      await sessionInstance.setActive(true);
      debugPrint('[Polly] ✓ Recording session configured');
    } catch (e) {
      debugPrint('[Polly] ⚠ Recording session config failed: $e');
    }
  }

  static Future<void> _configurePlaybackDuringVoiceSession() async {
    try {
      debugPrint(
        '[Polly] Configuring AudioSession for playback (voice mode)...',
      );
      final sessionInstance = await session.AudioSession.instance;
      await sessionInstance.configure(
        session.AudioSessionConfiguration(
          avAudioSessionCategory: session.AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              session.AVAudioSessionCategoryOptions.defaultToSpeaker |
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
      await sessionInstance.setActive(true);
      debugPrint('[Polly] ✓ Playback (voice mode) session configured');
    } catch (e) {
      debugPrint('[Polly] ⚠ Playback session config failed: $e');
    }
  }

  static Future<Uint8List?> _synthesizeAudio(
    String text,
    _PollyVoiceConfig config,
  ) async {
    try {
      debugPrint('[Polly] Synthesizing via AWS Polly (${config.voiceId})...');

      final now = DateTime.now().toUtc();
      final uri = Uri.parse('https://polly.$_region.amazonaws.com/v1/speech');

      final bodyJson = jsonEncode({
        'Text': text,
        'OutputFormat': 'mp3',
        'VoiceId': config.voiceId,
        'Engine': config.engine,
      });
      final bodyBytes = Uint8List.fromList(utf8.encode(bodyJson));

      final signer = _AwsV4Signer(
        accessKey: _accessKey,
        secretKey: _secretKey,
        region: _region,
      );

      final headers = signer.sign(
        method: 'POST',
        uri: uri,
        headers: {'content-type': 'application/json'},
        body: bodyBytes,
        dateTime: now,
      );

      final response = await http
          .post(uri, headers: headers, body: bodyBytes)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('[Polly] ✓ Synthesized ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      }

      debugPrint('[Polly] ❌ API error ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[Polly] ❌ Synthesis failed: $e');
      return null;
    }
  }

  static Future<void> _playAudio(
    Uint8List mp3Bytes,
    VoidCallback? onReady,
    VoidCallback onDone,
  ) async {
    try {
      debugPrint('[Polly] Preparing audio (${mp3Bytes.length} bytes)...');

      await _configurePlaybackDuringVoiceSession();

      await Future.delayed(const Duration(milliseconds: 800));

      await _loadAndPlayBytes(mp3Bytes, onReady, onDone);
    } catch (e) {
      debugPrint('[Polly] ❌ Playback setup failed: $e');
      onDone();
    }
  }

  static Future<void> _loadAndPlayBytes(
    Uint8List mp3Bytes,
    VoidCallback? onReady,
    VoidCallback onDone,
  ) async {
    debugPrint('[Polly] _loadAndPlayBytes START');

    final player = _player!;
    bool onReadyCalled = false;
    bool onDoneCalled = false;
    ProcessingState? lastProcessingState;
    bool playbackCompletedEmitted = false;

    void callOnDone() {
      if (!onDoneCalled) {
        onDoneCalled = true;
        _stateSubscription?.cancel();
        _stateSubscription = null;
        debugPrint('[Polly] ✓ onDone called');
        onDone();
      }
    }

    _stateSubscription?.cancel();
    _stateSubscription = player.playerStateStream.listen((state) {
      debugPrint(
        '[Polly] Player state: playing=${state.playing}, processingState=${state.processingState}, lastState=$lastProcessingState',
      );

      if (state.playing && !onReadyCalled) {
        onReadyCalled = true;
        debugPrint('[Polly] ✓ Audio started, calling onReady');
        onReady?.call();
      }

      if (onReadyCalled && lastProcessingState != null) {
        final isIosCompletion =
            lastProcessingState == ProcessingState.buffering &&
            state.processingState == ProcessingState.idle;
        final isAndroidCompletion =
            lastProcessingState == ProcessingState.ready &&
            state.processingState == ProcessingState.completed;

        if ((isIosCompletion || isAndroidCompletion) &&
            !playbackCompletedEmitted) {
          debugPrint(
            '[Polly] Playback complete: $lastProcessingState → ${state.processingState}',
          );
          playbackCompletedEmitted = true;

          if (!_stopRequested) {
            _playbackCompletedController.add(null);
          }

          callOnDone();
        }
      }

      lastProcessingState = state.processingState;
    });

    int attempts = 0;
    bool loaded = false;

    while (attempts < 3 && !loaded && !_stopRequested) {
      try {
        attempts++;
        debugPrint('[Polly] ════════════ LOAD ATTEMPT $attempts ════════════');

        debugPrint('[Polly] Calling setAudioSource with data URI...');
        await player.setAudioSource(
          AudioSource.uri(Uri.dataFromBytes(mp3Bytes, mimeType: 'audio/mpeg')),
          initialPosition: Duration.zero,
          preload: true,
        );

        debugPrint('[Polly] ✓ setAudioSource completed');
        loaded = true;
      } catch (e, st) {
        debugPrint('[Polly] ❌ Load attempt $attempts failed: $e');
        debugPrint('[Polly] Stack trace: $st');

        if (attempts < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      }
    }

    if (!loaded) {
      debugPrint('[Polly] ❌ Failed to load after 3 attempts');
      if (onReady != null) onReady();

      final estimatedDurationMs = ((mp3Bytes.length / 128000) * 1000 * 8)
          .toInt();
      await Future.delayed(Duration(milliseconds: estimatedDurationMs));

      callOnDone();
      return;
    }

    if (_stopRequested) {
      debugPrint('[Polly] Stop requested, skipping play()');
      callOnDone();
      return;
    }

    try {
      debugPrint('[Polly] Calling play()...');
      await player.play();
      debugPrint('[Polly] ✓ play() completed');
    } catch (e) {
      debugPrint('[Polly] ❌ Play failed: $e');
      callOnDone();
    }
  }

  static Future<void> _stopPlayer() async {
    _stateSubscription?.cancel();
    _stateSubscription = null;

    final p = _player;
    if (p != null) {
      try {
        await p.stop();
        await p.seek(Duration.zero);
        debugPrint('[Polly] ✓ Player stopped');
      } catch (e) {
        debugPrint('[Polly] ⚠ Player stop error: $e');
      }
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

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
