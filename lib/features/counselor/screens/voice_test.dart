import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

const _pollyVoices = [
  {
    'name': 'Matthew',
    'id': 'Matthew',
    'gender': 'M',
    'vibe': 'Deep, warm American',
  },
  {
    'name': 'Joanna',
    'id': 'Joanna',
    'gender': 'F',
    'vibe': 'Clear, professional American',
  },
  {
    'name': 'Joey',
    'id': 'Joey',
    'gender': 'M',
    'vibe': 'Friendly, casual American',
  },
  {
    'name': 'Salli',
    'id': 'Salli',
    'gender': 'F',
    'vibe': 'Gentle, expressive American',
  },
  {
    'name': 'Ruth',
    'id': 'Ruth',
    'gender': 'F',
    'vibe': 'Precise, professional American',
  },
  {
    'name': 'Danielle',
    'id': 'Danielle',
    'gender': 'F',
    'vibe': 'Warm, engaging American',
  },
  {
    'name': 'Stephen',
    'id': 'Stephen',
    'gender': 'M',
    'vibe': 'Calm, measured neutral',
  },
  {
    'name': 'Ivy',
    'id': 'Ivy',
    'gender': 'F',
    'vibe': 'Young, childlike American',
  },
  {
    'name': 'Kevin',
    'id': 'Kevin',
    'gender': 'M',
    'vibe': 'Young, energetic American',
  },
  {
    'name': 'Kendra',
    'id': 'Kendra',
    'gender': 'F',
    'vibe': 'Warm, smooth American',
  },
  {
    'name': 'Kimberly',
    'id': 'Kimberly',
    'gender': 'F',
    'vibe': 'Bright, clear American',
  },
  {
    'name': 'Justin',
    'id': 'Justin',
    'gender': 'M',
    'vibe': 'Young, boyish American',
  },
  {'name': 'Amy', 'id': 'Amy', 'gender': 'F', 'vibe': 'Professional, British'},
  {'name': 'Brian', 'id': 'Brian', 'gender': 'M', 'vibe': 'Deep, British'},
  {'name': 'Emma', 'id': 'Emma', 'gender': 'F', 'vibe': 'Warm, British'},
  {
    'name': 'Aria',
    'id': 'Aria',
    'gender': 'F',
    'vibe': 'Calm, expressive New Zealand',
  },
  {
    'name': 'Ayanda',
    'id': 'Ayanda',
    'gender': 'F',
    'vibe': 'Warm, South African',
  },
  {'name': 'Gregory', 'id': 'Gregory', 'gender': 'M', 'vibe': 'Deep, American'},
  {'name': 'Liam', 'id': 'Liam', 'gender': 'M', 'vibe': 'Neutral, Canadian'},
  {'name': 'Olivia', 'id': 'Olivia', 'gender': 'F', 'vibe': 'Warm, Australian'},
];

const _testPhrase =
    "Hello. I can help you figure out the best path forward — just tell me what you're working on.";

// ─────────────────────────────────────────────────────────────
// AWS V4 SIGNER (simplified for tester)
// ─────────────────────────────────────────────────────────────

class _AwsV4Signer {
  final String accessKey;
  final String secretKey;
  final String region;

  _AwsV4Signer({
    required this.accessKey,
    required this.secretKey,
    required this.region,
  });

  Map<String, String> sign({
    required Uri uri,
    required Uint8List body,
    required DateTime dateTime,
  }) {
    const service = 'polly';
    final dateStamp = _fmtDate(dateTime);
    final amzDate = _fmtAmzDate(dateTime);
    final credScope = '$dateStamp/$region/$service/aws4_request';

    final headers = <String, String>{
      'content-type': 'application/json',
      'host': uri.host,
      'x-amz-date': amzDate,
    };

    final sortedKeys = headers.keys.toList()..sort();
    final canonHeaders = sortedKeys
        .map((k) => '${k}:${headers[k]!}')
        .join('\n');
    final signedHeaderStr = sortedKeys.join(';');
    final payloadHash = sha256.convert(body).toString();

    final canonReq = [
      'POST',
      uri.path,
      uri.query,
      '$canonHeaders\n',
      signedHeaderStr,
      payloadHash,
    ].join('\n');
    final sts = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credScope,
      sha256.convert(utf8.encode(canonReq)).toString(),
    ].join('\n');

    final kDate = _hmac(utf8.encode('AWS4$secretKey'), dateStamp);
    final kRegion = _hmac(kDate, region);
    final kService = _hmac(kRegion, service);
    final kSigning = _hmac(kService, 'aws4_request');
    final sig = Hmac(sha256, kSigning).convert(utf8.encode(sts)).toString();

    return {
      ...headers,
      'authorization':
          'AWS4-HMAC-SHA256 Credential=$accessKey/$credScope, SignedHeaders=$signedHeaderStr, Signature=$sig',
      'x-amz-content-sha256': payloadHash,
    };
  }

  List<int> _hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _fmtAmzDate(DateTime dt) =>
      '${_fmtDate(dt)}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}Z';
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class VoiceTesterScreen extends StatefulWidget {
  const VoiceTesterScreen({super.key});

  @override
  State<VoiceTesterScreen> createState() => _VoiceTesterScreenState();
}

class _VoiceTesterScreenState extends State<VoiceTesterScreen> {
  String? _playingId;
  String? _loadingId;
  AudioPlayer? _activePlayer;
  final TextEditingController _phraseCtrl = TextEditingController(
    text: _testPhrase,
  );

  @override
  void dispose() {
    _activePlayer?.dispose();
    _phraseCtrl.dispose();
    super.dispose();
  }

  Future<void> _play(String voiceId) async {
    if (_loadingId == voiceId) return;

    // Stop current
    await _activePlayer?.stop();
    await _activePlayer?.dispose();
    _activePlayer = null;
    setState(() {
      _playingId = null;
      _loadingId = voiceId;
    });

    try {
      final accessKey = dotenv.env['AWS_ACCESS_KEY_ID'] ?? '';
      final secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '';
      final region = dotenv.env['AWS_REGION'] ?? 'us-east-1';

      if (accessKey.isEmpty || secretKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing AWS credentials in .env')),
          );
        }
        setState(() => _loadingId = null);
        return;
      }

      final now = DateTime.now().toUtc();
      final uri = Uri.parse('https://polly.$region.amazonaws.com/v1/speech');
      final bodyJson = jsonEncode({
        'Text': _phraseCtrl.text.trim().isEmpty
            ? _testPhrase
            : _phraseCtrl.text.trim(),
        'OutputFormat': 'mp3',
        'VoiceId': voiceId,
        'Engine': 'neural',
      });
      final bodyBytes = Uint8List.fromList(utf8.encode(bodyJson));

      final signer = _AwsV4Signer(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
      );

      final headers = signer.sign(uri: uri, body: bodyBytes, dateTime: now);

      final response = await http.post(uri, headers: headers, body: bodyBytes);

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ${response.statusCode}: ${response.body}'),
            ),
          );
        }
        setState(() => _loadingId = null);
        return;
      }

      final freshPlayer = AudioPlayer();
      _activePlayer = freshPlayer;
      await freshPlayer.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(response.bodyBytes, mimeType: 'audio/mpeg'),
        ),
      );

      setState(() {
        _playingId = voiceId;
        _loadingId = null;
      });

      await freshPlayer.play();
      await freshPlayer.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed,
      );
      if (mounted) setState(() => _playingId = null);
      await freshPlayer.dispose();
      _activePlayer = null;
    } catch (e) {
      debugPrint('[VoiceTester] $e');
      if (mounted) setState(() => _loadingId = null);
    }
  }

  Future<void> _stop() async {
    await _activePlayer?.stop();
    setState(() => _playingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('🎙 Voice Tester (Polly)'),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _phraseCtrl,
              decoration: InputDecoration(
                hintText: 'Type a test phrase…',
                filled: true,
                fillColor: colors.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: Icon(
                  Icons.edit_rounded,
                  color: colors.onSurface.withOpacity(0.3),
                  size: 18,
                ),
              ),
              style: textTheme.bodyMedium,
              maxLines: 1,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _pollyVoices.length,
        itemBuilder: (context, i) {
          final voice = _pollyVoices[i];
          final id = voice['id']!;
          final isPlaying = _playingId == id;
          final isLoading = _loadingId == id;
          final isFemale = voice['gender'] == 'F';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPlaying
                    ? colors.primary.withOpacity(0.15)
                    : colors.surfaceContainerHighest.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isFemale ? '♀' : '♂',
                  style: TextStyle(
                    fontSize: 16,
                    color: isPlaying
                        ? colors.primary
                        : colors.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            title: Text(
              voice['name']!,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isPlaying ? colors.primary : colors.onSurface,
              ),
            ),
            subtitle: Text(
              voice['vibe']!,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.45),
                fontSize: 11,
              ),
            ),
            trailing: SizedBox(
              width: 44,
              height: 44,
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: isPlaying ? _stop : () => _play(id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? colors.primary.withOpacity(0.12)
                              : colors.surfaceContainerHighest.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPlaying
                                ? colors.primary.withOpacity(0.4)
                                : colors.outline.withOpacity(0.15),
                          ),
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlaying
                              ? colors.primary
                              : colors.onSurface.withOpacity(0.6),
                          size: 22,
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
