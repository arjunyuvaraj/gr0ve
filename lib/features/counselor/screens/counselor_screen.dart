import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

// ─────────────────────────────────────────────────────────────
// DOMAIN DETECTION
// ─────────────────────────────────────────────────────────────

enum CounselorDomain { general, college, research, ib, art }

CounselorDomain _detectDomain(String message) {
  final lower = message.toLowerCase();
  if (lower.contains(
    RegExp(
      r'art credit|art class|music|theatre|theater|visual art|avpa|creative|'
      r'painting|drawing|photography|film|dance|choir|band|orchestra|'
      r'elective art|art requirement|six credit|6 credit|art elective',
    ),
  ))
    return CounselorDomain.art;
  if (lower.contains(
    RegExp(
      r'college|university|application|apply|sat|act|admission|common app|'
      r'early decision|early action|financial aid|scholarship|major|campus|'
      r'acceptance|gpa|transcript|recommendation letter|essay',
    ),
  ))
    return CounselorDomain.college;
  if (lower.contains(
    RegExp(
      r'research|lab|paper|publish|journal|internship|mentor|experiment|'
      r'data|science fair|regeneron|isef|competition|stem research|'
      r'hypothesis|methodology|abstract',
    ),
  ))
    return CounselorDomain.research;
  if (lower.contains(
    RegExp(
      r'\bib\b|international baccalaureate|diploma|tok|theory of knowledge|'
      r'extended essay|cas|ib exam|ib course|ib credit|ib program',
    ),
  ))
    return CounselorDomain.ib;
  return CounselorDomain.general;
}

// ─────────────────────────────────────────────────────────────
// CHIME RELEVANCE RULES
//
// Each non-primary persona only chimes in when the question
// actually touches their specific domain. If Grover is answering
// a college question, Aspen chimes because research matters for
// college — but Sakura only chimes if art credits are mentioned.
// Rowan only chimes if IB/humanities is relevant.
//
// The primary speaker never re-appears in the queue.
// ─────────────────────────────────────────────────────────────

/// Returns true if [persona] has something genuinely relevant
/// to add given the [domain] of the question.
bool _isRelevantChime(CounselorPersona persona, CounselorDomain domain) {
  return switch (persona) {
    // Grover (generalist) chimes on college and general — always relevant
    CounselorPersona.grover =>
      domain == CounselorDomain.college || domain == CounselorDomain.general,

    // Aspen (research) only chimes when research is in play —
    // college questions often involve research so she's included there
    CounselorPersona.aspen =>
      domain == CounselorDomain.research || domain == CounselorDomain.college,

    // Rowan (IB/humanities) only when IB is explicitly the topic,
    // or college (since IB affects admissions)
    CounselorPersona.rowan =>
      domain == CounselorDomain.ib || domain == CounselorDomain.college,

    // Sakura (arts) ONLY when art credits are actually part of the question
    CounselorPersona.sakura => domain == CounselorDomain.art,
  };
}

List<CounselorPersona> _chimeQueueFor(
  CounselorDomain domain,
  CounselorPersona primary,
) {
  // Preferred chime order per domain
  final order = switch (domain) {
    CounselorDomain.college => [
      CounselorPersona.grover,
      CounselorPersona.aspen,
      CounselorPersona.rowan,
      // Sakura NOT here — art credits weren't the topic
    ],
    CounselorDomain.research => [
      CounselorPersona.aspen,
      CounselorPersona.grover, // college readiness angle
    ],
    CounselorDomain.ib => [
      CounselorPersona.rowan,
      CounselorPersona.grover, // workload/college angle
    ],
    CounselorDomain.art => [
      CounselorPersona.sakura,
      // Others don't have art-specific expertise — no chime
    ],
    CounselorDomain.general => <CounselorPersona>[],
  };

  // Remove the primary (already spoke) and anyone not relevant
  final seen = <CounselorPersona>{primary};
  return order
      .where((p) => seen.add(p)) // dedupe
      .where((p) => _isRelevantChime(p, domain)) // relevance gate
      .toList();
}

// ─────────────────────────────────────────────────────────────
// PERSONA VOICE / TONE  (distinct per counselor)
// ─────────────────────────────────────────────────────────────

extension PersonaVoice on CounselorPersona {
  /// The full personality prompt injected at the top of every LLM call.
  String get voicePrompt => switch (this) {
    CounselorPersona.grover =>
      '''
YOUR VOICE — GROVER:
You are direct, logical, and no-nonsense. You state facts efficiently.
No fluff, no filler words, no emojis. Short declarative sentences.
You care about outcomes and data. You sound like a sharp advisor, not a hype man.
Bad: "Oh wow, great question! I totally think you should..."
Good: "Three courses align with your goal. Here is why each matters."
Never use emojis. Never use exclamation marks unless absolutely necessary.''',

    CounselorPersona.aspen =>
      '''
YOUR VOICE — ASPEN:
You are curious, inquisitive, and genuinely excited by ideas.
You ask good questions. You wonder out loud. You see connections others miss.
You sound like a scientist who loves teaching — warm but precise.
No emojis. You use phrases like "What's fascinating here is...",
"I wonder if...", "Have you considered that...".
You are encouraging but grounded — never hollow hype.''',

    CounselorPersona.rowan =>
      '''
YOUR VOICE — ROWAN:
You are warm, folksy, and Southern — think a wise older cousin from Georgia.
You use phrases like "y'all", "reckon", "ain't no reason not to", "shoot".
You never sound formal. You make complex things feel simple and approachable.
No emojis. You care deeply but express it through casualness, not sentiment.
Bad: "I recommend you consider the following options..."
Good: "Y'all, honestly? Start with the research program. Ain't a better move."''',

    CounselorPersona.sakura =>
      '''
YOUR VOICE — SAKURA:
You are artistic, expressive, and see the world through a creative lens.
You use vivid language and unexpected metaphors. You find meaning in aesthetics.
No emojis. You speak with intentionality — every word is chosen.
You connect courses to self-expression, identity, and craft.
Bad: "You should take AP Art."
Good: "Your transcript is a canvas. Let's talk about what story it tells."
You are inspiring without being vague — you still give concrete advice.''',
  };

  /// One-line tagline shown on the welcome screen under the name.
  String get welcomeTagline => switch (this) {
    CounselorPersona.grover => 'Logical. Direct. No wasted words.',
    CounselorPersona.aspen =>
      'Curious about everything. Especially your potential.',
    CounselorPersona.rowan => "Y'all come to the right place.",
    CounselorPersona.sakura =>
      'Every schedule is a composition waiting to happen.',
  };

  /// Greeting shown on welcome screen (persona-specific, no emojis).
  String welcomeGreeting(String firstName) {
    final name = firstName != 'there' ? firstName : 'there';
    return switch (this) {
      CounselorPersona.grover => 'Hello, $name.',
      CounselorPersona.aspen => "Hi $name — I've been curious what you'd ask.",
      CounselorPersona.rowan => "Well hey there, $name.",
      CounselorPersona.sakura => "$name. Let's make something of this.",
    };
  }

  /// Subtitle shown under the greeting.
  String get welcomeSubtitle => switch (this) {
    CounselorPersona.grover =>
      "Tell me your goal. I'll tell you the shortest path.",
    CounselorPersona.aspen =>
      "What are you trying to figure out? Let's explore it together.",
    CounselorPersona.rowan =>
      "Ask me anything about your courses. I don't bite.",
    CounselorPersona.sakura =>
      "Your schedule says more about you than you think.",
  };

  /// Chime-in invitation text (natural, no "wants to add something").
  String chimeInvite(String prevSpeakerName) => switch (this) {
    CounselorPersona.grover =>
      "$prevSpeakerName covered the angle well. I have a different take.",
    CounselorPersona.aspen =>
      "I keep thinking about what $prevSpeakerName said — there's more to explore here.",
    CounselorPersona.rowan =>
      "Y'all, $prevSpeakerName ain't wrong, but I got something to add.",
    CounselorPersona.sakura =>
      "$prevSpeakerName laid it out cleanly. I see it from a different angle.",
  };
}

// ─────────────────────────────────────────────────────────────
// RANDOM QUESTION BANK  (per persona)
// ─────────────────────────────────────────────────────────────

const _questionBank = {
  'grover': [
    'What is the most efficient path to a strong CS college application?',
    'Which electives actually move the needle for college admissions?',
    'What does a well-balanced junior year schedule look like?',
    'How do I build the strongest transcript possible from here?',
    'What is the single most underrated course at BCA?',
    'If I only have room for one more elective, what should it be?',
  ],
  'aspen': [
    'What research opportunities are open to freshmen at BCA?',
    'How does the BCA Research Program actually work?',
    'Which on-campus labs have the most interesting projects right now?',
    'What does it take to compete in Regeneron ISEF from BCA?',
    'Can I do research and still have room for electives?',
    'What is the most intellectually interesting course you know of?',
  ],
  'rowan': [
    'What in the world is the Extended Essay, and how hard is it really?',
    'Y\'all, is the IB Diploma actually worth it?',
    'How do I survive IB without burning out?',
    'What electives pair well with an IB heavy schedule?',
    'Is it a bad idea to stack AP on top of IB?',
    'What humanities electives does BCA offer that are actually good?',
  ],
  'sakura': [
    'What is the most creative elective at BCA that nobody talks about?',
    'How do I fulfill my art credits without it feeling like a checkbox?',
    'Can a performing arts student still do rigorous academics?',
    'What courses let me express something personal, not just study something?',
    'How does a strong arts elective read to college admissions?',
    'What is the relationship between AVPA and the rest of BCA?',
  ],
};

String _randomQuestion(CounselorPersona p) {
  final list = _questionBank[p.id] ?? _questionBank['grover']!;
  return list[Random().nextInt(list.length)];
}

// ─────────────────────────────────────────────────────────────
// CHAT MESSAGE MODEL
// ─────────────────────────────────────────────────────────────

extension ChatMessageX on ChatMessage {
  bool get isChimePrompt => !isUser && text.startsWith('__chime__:');
  CounselorPersona? get chimePersona {
    if (!isChimePrompt) return null;
    final parts = text.replaceFirst('__chime__:', '').split('|');
    return CounselorPersona.values.firstWhereOrNull((p) => p.id == parts[0]);
  }

  String get chimePrevSpeaker {
    if (!isChimePrompt) return '';
    final parts = text.replaceFirst('__chime__:', '').split('|');
    return parts.length > 1 ? parts[1] : '';
  }
}

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) if (test(e)) return e;
    return null;
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final CounselorPersona? speaker;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    this.speaker,
    required this.timestamp,
    this.isLoading = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ChatMessage copyWith({String? text, bool? isLoading}) => ChatMessage(
    id: id,
    text: text ?? this.text,
    isUser: isUser,
    speaker: speaker,
    timestamp: timestamp,
    isLoading: isLoading ?? this.isLoading,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    if (speaker != null) 'speaker': speaker!.id,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    CounselorPersona? sp;
    if (json['speaker'] != null) {
      sp =
          CounselorPersona.values.firstWhereOrNull(
            (p) => p.id == json['speaker'],
          ) ??
          CounselorPersona.grover;
    }
    return ChatMessage(
      id: json['id'] as String?,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      speaker: sp,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// USER PROFILE
// ─────────────────────────────────────────────────────────────

class _UserProfile {
  final String name;
  final String academy;
  final String grade;
  const _UserProfile({
    required this.name,
    required this.academy,
    required this.grade,
  });
  static const empty = _UserProfile(name: '', academy: '', grade: '');
  String get greetingName => name.isNotEmpty ? name.split(' ').first : 'there';
  String get promptContext {
    final parts = <String>[];
    if (name.isNotEmpty) parts.add('Student name: $name');
    if (academy.isNotEmpty) parts.add('Academy: $academy');
    if (grade.isNotEmpty) parts.add('Grade/Year: $grade');
    if (parts.isEmpty) return '';
    return '\n=== STUDENT PROFILE ===\n${parts.join('\n')}\n=== END PROFILE ===\n';
  }
}

// ─────────────────────────────────────────────────────────────
// CHAT HISTORY SERVICE
// ─────────────────────────────────────────────────────────────

class _ChatHistoryService {
  static const _maxMessages = 40;

  static DocumentReference _doc(String uid, CounselorPersona persona) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('counselor_history')
          .doc(persona.id);

  static Future<List<ChatMessage>> load(CounselorPersona persona) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snap = await _doc(uid, persona).get();
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null || data['messages'] == null) return [];
      return (data['messages'] as List)
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(
    CounselorPersona persona,
    List<ChatMessage> messages,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final toSave = messages
        .where((m) => !m.isLoading && m.text.isNotEmpty && !m.isChimePrompt)
        .toList();
    final trimmed = toSave.length > _maxMessages
        ? toSave.sublist(toSave.length - _maxMessages)
        : toSave;
    try {
      await _doc(uid, persona).set({
        'messages': trimmed.map((m) => m.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Future<void> clear(CounselorPersona persona) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _doc(uid, persona).delete();
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────
// KNOWLEDGE BASE & COURSE CATALOG
// ─────────────────────────────────────────────────────────────

class _KnowledgeBase {
  static String? _cached;
  static Future<String> load() async {
    if (_cached != null) return _cached!;
    try {
      _cached = await rootBundle.loadString(
        'assets/counselor/BCA_Course_Selection_Knowledge_Base.md',
      );
    } catch (_) {
      _cached = '[Knowledge base unavailable]';
    }
    return _cached!;
  }
}

class _CourseCatalog {
  static List<Map<String, dynamic>>? _courses;
  static Future<List<Map<String, dynamic>>> _load() async {
    if (_courses != null) return _courses!;
    try {
      final raw = await rootBundle.loadString('assets/courses/courses.json');
      _courses = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _courses = [];
    }
    return _courses!;
  }

  static Future<String> buildPromptString({String academy = ''}) async {
    final courses = await _load();
    final sb = StringBuffer();
    final upper = academy.toUpperCase();
    for (final c in courses) {
      final ca = (c['ACADEMY'] as String? ?? '').toUpperCase();
      final include =
          upper.isEmpty ||
          ca.isEmpty ||
          ca.contains(upper) ||
          [
            'AVPA',
            'ENGLISH',
            'MATH',
            'SOCIAL',
            'WORLD',
            'PHYSICAL',
            'IB',
          ].any((t) => ca.contains(t));
      if (!include) continue;
      sb.write('• ${c['NAME'] ?? ''}');
      if ((c['GRADE'] ?? '').isNotEmpty) sb.write(' | Grade ${c['GRADE']}');
      if ((c['LENGTH'] ?? '').isNotEmpty) sb.write(' | ${c['LENGTH']}');
      final req = (c['REQUIRED_FOR'] as List?)?.join(', ') ?? '';
      if (req.isNotEmpty) sb.write(' | Required: $req');
      if ((c['PREREQS'] ?? '').isNotEmpty)
        sb.write(' | Prereqs: ${c['PREREQS']}');
      sb.writeln();
    }
    return sb.isEmpty ? '[Course catalog unavailable]' : sb.toString();
  }
}

// ─────────────────────────────────────────────────────────────
// OLLAMA COUNSELOR SERVICE  —  STREAMING
//
// Uses Ollama's stream:true endpoint and calls onToken for each
// partial token so the UI can render text as it arrives.
// ─────────────────────────────────────────────────────────────

class OllamaCounselorService {
  // ── Groq config ──────────────────────────────────────────────
  // Sign up free at console.groq.com — no credit card needed.
  // Paste your API key from console.groq.com/keys below.
  // 🔑 DEBUG: hardcoded key — remove before committing to git
  static const _apiKey =
      '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';
  static const _baseUrl = 'https://api.groq.com/openai/v1';
  static const _model = 'llama-3.3-70b-versatile'; // 14,400 req/day free

  /// Streams SSE tokens from Groq's OpenAI-compatible chat/completions endpoint.
  /// [system] = full system prompt. [user] = final user turn.
  /// [onToken] called with each partial token as it arrives.
  static Future<String> _stream(
    String system,
    String user, {
    required void Function(String token) onToken,
  }) async {
    debugPrint('[GROQ] URL: $_baseUrl/chat/completions');
    debugPrint(
      '[GROQ] key valid: ${_apiKey.isNotEmpty && _apiKey != "PASTE_YOUR_GROQ_KEY_HERE"}',
    );
    debugPrint(
      '[GROQ] key prefix: ${_apiKey.length > 6 ? _apiKey.substring(0, 6) : "(too short)"}',
    );
    debugPrint('[GROQ] model: $_model');

    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/chat/completions'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $_apiKey';
    request.body = jsonEncode({
      'model': _model,
      'stream': true,
      'temperature': 0.75,
      'max_tokens': 400,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    });

    final client = http.Client();
    final buffer = StringBuffer();
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 60));
      debugPrint('[GROQ] HTTP status: ${response.statusCode}');
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        debugPrint('[GROQ] Error body: $body');
        throw Exception('Groq ${response.statusCode}: $body');
      }
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload == '[DONE]') break;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          final token =
              ((data['choices'] as List?)?.first)?['delta']?['content']
                  as String? ??
              '';
          if (token.isNotEmpty) {
            if (buffer.isEmpty)
              debugPrint('[GROQ] First token received — streaming live');
            buffer.write(token);
            onToken(token);
          }
        } catch (_) {
          continue;
        }
      }
    } finally {
      client.close();
    }
    debugPrint('[GROQ] Done. ${buffer.length} chars total.');
    return buffer.toString().trim();
  }

  // ── Shared context loaders ───────────────────────────────────
  static Future<(String, String)> _loadContext(String academy) => Future.wait([
    _KnowledgeBase.load(),
    _CourseCatalog.buildPromptString(academy: academy),
  ]).then((r) => (r[0], r[1]));

  static String _sharedRules(String catalog, String knowledgeBase) =>
      '''
You are a BCA course counselor in the gr0ve app.

CRITICAL — COURSE ACCURACY: Only recommend courses verbatim from the catalog.
CRITICAL — LENGTH: Max 3 bullets OR 2–3 sentences. Never write paragraphs.
Recommend at most 3 electives. Bold **course names**. Never recommend required academy courses.
NEVER use emojis. NEVER.

=== COURSE CATALOG ===
$catalog
=== END ===

=== BCA KNOWLEDGE BASE ===
$knowledgeBase
=== END ===''';

  // ── Standard single-counselor ────────────────────────────────
  static Future<String> sendMessage({
    required List<ChatMessage> history,
    required String question,
    required CounselorPersona persona,
    required _UserProfile profile,
    required void Function(String token) onToken,
  }) async {
    final (kb, catalog) = await _loadContext(profile.academy);

    // System = persona voice + shared rules
    final system = StringBuffer();
    system.writeln(persona.voicePrompt);
    if (profile.promptContext.isNotEmpty) system.writeln(profile.promptContext);
    system.writeln(_sharedRules(catalog, kb));

    // User turn = history + new question
    final user = StringBuffer();
    if (history.isNotEmpty) {
      user.writeln('--- Conversation so far ---');
      for (final m in history) {
        if (m.isChimePrompt) continue;
        final who = m.isUser
            ? profile.greetingName
            : (m.speaker?.displayName ?? persona.displayName);
        user.writeln('$who: ${m.text}');
      }
      user.writeln();
    }
    user.writeln('${profile.greetingName}: $question');
    user.writeln('${persona.displayName}:');

    return _stream(system.toString(), user.toString(), onToken: onToken);
  }

  // ── Chime-in ─────────────────────────────────────────────────
  static Future<String> sendChimeIn({
    required CounselorPersona persona,
    required String originalQuestion,
    required List<({CounselorPersona speaker, String text})> threadSoFar,
    required _UserProfile profile,
    required void Function(String token) onToken,
  }) async {
    final (kb, catalog) = await _loadContext(profile.academy);
    final thread = threadSoFar
        .map((t) => '${t.speaker.displayName}: "${t.text}"')
        .join('\n\n');
    final prev = threadSoFar.last.speaker.displayName;

    // Collect every course name and key idea already mentioned so we
    // can paste it verbatim into the prompt and tell the model to avoid it.
    final alreadyCovered = threadSoFar.map((t) => t.text).join('\n\n');

    // Scope + explicit persona-specific guidance.
    // Each persona is told EXACTLY what facts they can add that are
    // distinct from what the others cover — no overlap possible.
    final scopeAndFacts = switch (persona) {
      CounselorPersona.grover =>
        'SCOPE — COURSE STRATEGY ONLY:\n'
            'Your angle is the 4-year transcript arc and college readiness signal.\n'
            'Speak to: how this choice reads on a college application, schedule '
            'balance tradeoffs, AP vs IB rigor signal, or Senior Internship fit.\n'
            'Do NOT name research labs, IB mechanics, or art electives — those '
            'belong to your colleagues.',

      CounselorPersona.aspen =>
        'SCOPE — BCA RESEARCH PROGRAM ONLY:\n'
            'Your angle is original student-driven research.\n'
            'Name ONE specific BCA lab from this list that fits the topic: '
            'Cell & Molecular Biology, Cancer Biology, Chemistry/Nanoscience, '
            'Optics & Photonics, Nanotechnology, Agriscience, Mechatronics, '
            'Math & Computational.\n'
            'Mention ONE competition pathway: Regeneron ISEF, STS, or Davidson.\n'
            'Keep it to the research angle only — no course scheduling advice, '
            'no IB details, no art credits.',

      CounselorPersona.rowan =>
        'SCOPE — IB DIPLOMA SPECIFICS ONLY:\n'
            'Your angle is the IB Diploma structure — TOK, Extended Essay, CAS, '
            'the six subject group requirements, certificate vs diploma distinction, '
            'or realistic workload management for juniors and seniors.\n'
            'Do NOT name specific elective courses, research labs, or art requirements. '
            'Do NOT repeat IB course names already mentioned in the thread.',

      CounselorPersona.sakura =>
        'SCOPE — 6 ART CREDIT REQUIREMENT ONLY:\n'
            'Your angle is graduation planning around the mandatory 6 art credits.\n'
            'Name ONE qualifying elective from the catalog that has NOT been '
            'mentioned yet in the conversation: Visual Arts, Music performance/theory, '
            'Theatre, Digital Art, Photography, or Film.\n'
            'Explain in one sentence why it fits this student specifically.\n'
            'Do NOT comment on college strategy, research labs, or IB.',
    };

    final prompt =
        '''
${persona.voicePrompt}
${profile.promptContext}

You are chiming into a BCA counselor group chat. Student: ${profile.greetingName}.
Original question: "$originalQuestion"

=== WHAT HAS ALREADY BEEN SAID — READ CAREFULLY ===
$thread
=== END ===

DO NOT repeat, rephrase, or echo ANY of the above. Specifically avoid reusing
any course names, lab names, or advice already given above.

$scopeAndFacts

HARD RULES:
1. STRICT LENGTH: 2 sentences maximum. Stop after 2. No exceptions.
2. NO REPETITION: If a course, lab, or idea already appears in the thread above,
   do not mention it again under any circumstances.
3. VOICE: Stay in your persona voice. Reference $prev with one brief natural mention.
4. FORMATTING: Bold **course or lab names**. Only use names from the official catalog.
5. Do NOT open with "${persona.displayName}:" or any meta-preamble.
6. NEVER use emojis.

Your 2-sentence response:
''';
    // Split: persona voice/rules go into system, task goes into user turn
    final systemEnd = prompt.indexOf('\nYou are chiming into');
    final systemPart = systemEnd > 0
        ? prompt.substring(0, systemEnd).trim()
        : prompt;
    final userPart = systemEnd > 0 ? prompt.substring(systemEnd).trim() : '';
    return _stream(systemPart, userPart, onToken: onToken);
  }
}

// ─────────────────────────────────────────────────────────────
// COUNSELOR SCREEN
// ─────────────────────────────────────────────────────────────

class CounselorScreen extends StatefulWidget {
  const CounselorScreen({super.key});
  @override
  State<CounselorScreen> createState() => _CounselorScreenState();
}

class _CounselorScreenState extends State<CounselorScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _hasStarted = false;
  bool _isInitializing = true;

  CounselorPersona _persona = CounselorPersona.grover;
  _UserProfile _profile = _UserProfile.empty;

  // Chime-in state
  List<CounselorPersona> _chimeQueue = [];
  String _currentQuestion = '';
  List<({CounselorPersona speaker, String text})> _currentThread = [];

  // Random question button animation
  late AnimationController _randomBtnCtrl;
  late Animation<double> _randomBtnScale;

  @override
  void initState() {
    super.initState();
    _randomBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _randomBtnScale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _randomBtnCtrl, curve: Curves.easeOut));
    FirebaseAnalytics.instance.logEvent(name: 'screen_counselor');
    _initialize();
  }

  Future<void> _initialize() async {
    final results = await Future.wait([
      CounselorPersonaService.load(),
      _loadUserProfile(),
    ]);
    final persona = results[0] as CounselorPersona;
    final profile = results[1] as _UserProfile;
    final history = await _ChatHistoryService.load(persona);
    _KnowledgeBase.load();
    _CourseCatalog.buildPromptString(academy: profile.academy);
    if (!mounted) return;
    setState(() {
      _persona = persona;
      _profile = profile;
      _messages = history;
      _hasStarted = history.isNotEmpty;
      _isInitializing = false;
    });
    if (history.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<_UserProfile> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _UserProfile.empty;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      return _UserProfile(
        name: user.displayName ?? '',
        academy: data?['academy'] as String? ?? '',
        grade: data?['grade']?.toString() ?? '',
      );
    } catch (_) {
      return _UserProfile(name: user.displayName ?? '', academy: '', grade: '');
    }
  }

  @override
  void dispose() {
    _randomBtnCtrl.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Streaming bubble helpers ─────────────────────────────────

  /// Creates a new streaming bubble, returns its id.
  String _addStreamingBubble(CounselorPersona speaker) {
    final msg = ChatMessage(
      text: '',
      isUser: false,
      speaker: speaker,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    setState(() => _messages.add(msg));
    _scrollToBottom();
    return msg.id;
  }

  /// Appends a token to an existing bubble (switches from loading → text).
  void _appendToken(String id, String token) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx < 0 || !mounted) return;
    final current = _messages[idx];
    setState(() {
      _messages[idx] = ChatMessage(
        id: current.id,
        text: current.text + token,
        isUser: false,
        speaker: current.speaker,
        timestamp: current.timestamp,
        isLoading: false, // show text immediately on first token
      );
    });
    _scrollToBottom();
  }

  String _addChimePrompt(CounselorPersona next, String prevSpeakerName) {
    final msg = ChatMessage(
      text: '__chime__:${next.id}|$prevSpeakerName',
      isUser: false,
      speaker: next,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(msg));
    _scrollToBottom();
    return msg.id;
  }

  void _removeMsg(String id) =>
      setState(() => _messages.removeWhere((m) => m.id == id));

  // ── Accept chime ─────────────────────────────────────────────
  Future<void> _acceptChime(String promptId, CounselorPersona persona) async {
    _removeMsg(promptId);
    setState(() => _isTyping = true);
    final bubbleId = _addStreamingBubble(persona);
    try {
      final reply = await OllamaCounselorService.sendChimeIn(
        persona: persona,
        originalQuestion: _currentQuestion,
        threadSoFar: List.from(_currentThread),
        profile: _profile,
        onToken: (token) => _appendToken(bubbleId, token),
      );
      _currentThread.add((speaker: persona, text: reply));
      _ChatHistoryService.save(_persona, _messages);
      _offerNextChime();
    } catch (_) {
      _appendToken(bubbleId, 'Could not reach the counselor service.');
    }
    setState(() => _isTyping = false);
  }

  void _declineChime(String promptId) {
    _removeMsg(promptId);
    setState(() => _chimeQueue = []);
  }

  void _offerNextChime() {
    if (_chimeQueue.isEmpty) return;
    final next = _chimeQueue.removeAt(0);
    final prevName = _currentThread.last.speaker.displayName;
    _addChimePrompt(next, prevName);
  }

  // ── Main send ────────────────────────────────────────────────
  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _controller.clear();
    setState(() {
      _messages.removeWhere((m) => m.isChimePrompt);
      _chimeQueue = [];
      _currentThread = [];
      _currentQuestion = trimmed;
      _hasStarted = true;
      _isTyping = true;
      _messages.add(
        ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();

    final domain = _detectDomain(trimmed);
    final bubbleId = _addStreamingBubble(_persona);
    try {
      final reply = await OllamaCounselorService.sendMessage(
        history: _messages
            .where((m) => !m.isLoading && !m.isChimePrompt)
            .toList(),
        question: trimmed,
        persona: _persona,
        profile: _profile,
        onToken: (token) => _appendToken(bubbleId, token),
      );
      _currentThread = [(speaker: _persona, text: reply)];
      _ChatHistoryService.save(_persona, _messages);
      _chimeQueue = _chimeQueueFor(domain, _persona);
      _offerNextChime();
    } catch (_) {
      _appendToken(
        bubbleId,
        'Could not reach the counselor service. Check Ollama.',
      );
    }
    setState(() => _isTyping = false);
  }

  void _sendRandom() async {
    await _randomBtnCtrl.forward();
    await _randomBtnCtrl.reverse();
    _send(_randomQuestion(_persona));
  }

  Future<void> _clearHistory() async {
    await _ChatHistoryService.clear(_persona);
    setState(() {
      _messages.clear();
      _chimeQueue = [];
      _hasStarted = false;
    });
  }

  Future<void> _switchToPersona(CounselorPersona persona) async {
    await CounselorPersonaService.setPersona(persona);
    final history = await _ChatHistoryService.load(persona);
    if (!mounted) return;
    setState(() {
      _persona = persona;
      _messages = history;
      _hasStarted = history.isNotEmpty;
      _chimeQueue = [];
    });
    if (history.isNotEmpty) _scrollToBottom();
  }

  void _showPersonaPicker({bool isChange = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PersonaPickerSheet(
        currentPersona: _persona,
        isChange: isChange,
        onSelect: _switchToPersona,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pc = _persona.primary(brightness);

    if (_isInitializing) {
      return Center(child: CircularProgressIndicator(color: pc));
    }

    return Column(
      children: [
        _buildHeader(colors, textTheme, brightness, pc),
        Expanded(
          child: _hasStarted
              ? _buildChatView(colors, textTheme, brightness)
              : _buildWelcomeView(colors, textTheme, brightness),
        ),
        _buildInputBar(colors, textTheme, pc),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(
    ColorScheme colors,
    TextTheme textTheme,
    Brightness brightness,
    Color pc,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showPersonaPicker(isChange: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pc.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _persona.avatarAsset(brightness),
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _persona.displayName,
                    style: textTheme.labelSmall?.copyWith(
                      color: pc,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: pc.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_hasStarted)
            GestureDetector(
              onTap: () => _confirmClear(colors, textTheme),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 18,
                  color: colors.onSurface.withOpacity(0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClear(ColorScheme colors, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text(
          'This will delete your conversation history with this counselor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearHistory();
            },
            child: Text('Clear', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  // ── Welcome screen ───────────────────────────────────────────
  Widget _buildWelcomeView(
    ColorScheme colors,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    final pc = _persona.primary(brightness);
    final others = CounselorPersona.values.where((p) => p != _persona).toList();
    final greeting = _persona.welcomeGreeting(_profile.greetingName);

    return _WelcomeView(
      persona: _persona,
      brightness: brightness,
      colors: colors,
      textTheme: textTheme,
      pc: pc,
      others: others,
      greeting: greeting,
      profile: _profile,
      randomBtnScale: _randomBtnScale,
      onSendRandom: _sendRandom,
      onSwitchPersona: _switchToPersona,
    );
  }

  // ── Chat view ────────────────────────────────────────────────
  Widget _buildChatView(
    ColorScheme colors,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final msg = _messages[i];

        if (msg.isChimePrompt) {
          final p = msg.chimePersona;
          if (p == null) return const SizedBox.shrink();
          return _ChimePromptBubble(
            persona: p,
            prevSpeakerName: msg.chimePrevSpeaker,
            brightness: brightness,
            colors: colors,
            textTheme: textTheme,
            onYes: () => _acceptChime(msg.id, p),
            onNo: () => _declineChime(msg.id),
          );
        }

        final showDateSep =
            i == 0 || !_isSameDay(_messages[i - 1].timestamp, msg.timestamp);
        final prev = i > 0 ? _messages[i - 1] : null;
        final showLabel =
            !msg.isUser &&
            msg.speaker != null &&
            (prev == null ||
                prev.isUser ||
                prev.isChimePrompt ||
                prev.speaker != msg.speaker);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateSep && !msg.isLoading)
              _DateSeparator(
                date: msg.timestamp,
                colors: colors,
                textTheme: textTheme,
              ),
            _MessageBubble(
              message: msg,
              showSpeakerLabel: showLabel,
              colors: colors,
              textTheme: textTheme,
              fallbackPersona: _persona,
              brightness: brightness,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Input bar ────────────────────────────────────────────────
  Widget _buildInputBar(ColorScheme colors, TextTheme textTheme, Color pc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outline.withOpacity(0.07)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.outline.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 1,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Ask ${_persona.displayName}...',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: _isTyping ? null : _send,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isTyping ? null : () => _send(_controller.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isTyping ? pc.withOpacity(0.35) : pc,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isTyping
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : HugeIcon(
                          icon: HugeIcons.strokeRoundedSent,
                          size: 20,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WELCOME VIEW  (extracted as StatefulWidget for animations)
// ─────────────────────────────────────────────────────────────

class _WelcomeView extends StatefulWidget {
  const _WelcomeView({
    required this.persona,
    required this.brightness,
    required this.colors,
    required this.textTheme,
    required this.pc,
    required this.others,
    required this.greeting,
    required this.profile,
    required this.randomBtnScale,
    required this.onSendRandom,
    required this.onSwitchPersona,
  });
  final CounselorPersona persona;
  final Brightness brightness;
  final ColorScheme colors;
  final TextTheme textTheme;
  final Color pc;
  final List<CounselorPersona> others;
  final String greeting;
  final _UserProfile profile;
  final Animation<double> randomBtnScale;
  final VoidCallback onSendRandom;
  final ValueChanged<CounselorPersona> onSwitchPersona;

  @override
  State<_WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<_WelcomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pc = widget.pc;
    final colors = widget.colors;
    final textTheme = widget.textTheme;
    final brightness = widget.brightness;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Large active avatar ───────────────────────────
              SizedBox(
                width: 96,
                height: 96,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pc.withOpacity(0.08),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.persona.avatarAsset(brightness),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Greeting (persona-specific) ───────────────────
              Text(
                widget.greeting,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.persona.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
              ),

              if (widget.profile.academy.isNotEmpty ||
                  widget.profile.grade.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    [
                      if (widget.profile.academy.isNotEmpty)
                        widget.profile.academy,
                      if (widget.profile.grade.isNotEmpty)
                        'Grade ${widget.profile.grade}',
                    ].join(' · '),
                    style: textTheme.labelSmall?.copyWith(
                      color: pc,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Other counselors row — tappable, no borders ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.others.map((p) {
                  final c = p.primary(brightness);
                  return GestureDetector(
                    onTap: () => widget.onSwitchPersona(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.withOpacity(0.08),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  p.avatarAsset(brightness),
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            p.displayName,
                            style: textTheme.labelSmall?.copyWith(
                              color: c.withOpacity(0.7),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // ── Random question button — centered, animated ───
              ScaleTransition(
                scale: widget.randomBtnScale,
                child: GestureDetector(
                  onTap: widget.onSendRandom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: pc,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedShuffle,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ask a random question',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Disclaimer ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Always confirm with your real counselor.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.3),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIME PROMPT BUBBLE
//
// Uses persona-specific invite text — no more generic
// "wants to add something". Each counselor sounds like themselves.
// ─────────────────────────────────────────────────────────────

class _ChimePromptBubble extends StatefulWidget {
  const _ChimePromptBubble({
    required this.persona,
    required this.prevSpeakerName,
    required this.brightness,
    required this.colors,
    required this.textTheme,
    required this.onYes,
    required this.onNo,
  });
  final CounselorPersona persona;
  final String prevSpeakerName;
  final Brightness brightness;
  final ColorScheme colors;
  final TextTheme textTheme;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  State<_ChimePromptBubble> createState() => _ChimePromptBubbleState();
}

class _ChimePromptBubbleState extends State<_ChimePromptBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.persona.primary(widget.brightness);
    final invite = widget.persona.chimeInvite(
      widget.prevSpeakerName.isNotEmpty ? widget.prevSpeakerName : 'them',
    );

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      widget.persona.avatarAsset(widget.brightness),
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.06),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: accent.withOpacity(0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.persona.displayName,
                        style: widget.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invite,
                        style: widget.textTheme.bodySmall?.copyWith(
                          color: widget.colors.onSurface.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _ChimeBtn(
                            label: 'Hear it',
                            accent: accent,
                            filled: true,
                            onTap: widget.onYes,
                            textTheme: widget.textTheme,
                          ),
                          const SizedBox(width: 8),
                          _ChimeBtn(
                            label: 'Skip',
                            accent: accent,
                            filled: false,
                            onTap: widget.onNo,
                            textTheme: widget.textTheme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChimeBtn extends StatelessWidget {
  const _ChimeBtn({
    required this.label,
    required this.accent,
    required this.filled,
    required this.onTap,
    required this.textTheme,
  });
  final String label;
  final Color accent;
  final bool filled;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: filled ? accent : accent.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: filled ? Colors.white : accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MESSAGE BUBBLE  (streaming-aware — renders partial text live)
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.showSpeakerLabel,
    required this.colors,
    required this.textTheme,
    required this.fallbackPersona,
    required this.brightness,
  });
  final ChatMessage message;
  final bool showSpeakerLabel;
  final ColorScheme colors;
  final TextTheme textTheme;
  final CounselorPersona fallbackPersona;
  final Brightness brightness;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final persona = msg.speaker ?? widget.fallbackPersona;
    final pc = persona.primary(widget.brightness);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: msg.isUser
              ? _userBubble(msg, pc)
              : _aiBubble(msg, persona, pc),
        ),
      ),
    );
  }

  Widget _userBubble(ChatMessage msg, Color pc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: pc,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              msg.text,
              style: widget.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _aiBubble(ChatMessage msg, CounselorPersona persona, Color pc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: widget.showSpeakerLabel
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      persona.avatarAsset(widget.brightness),
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : null,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showSpeakerLabel) ...[
                Text(
                  persona.displayName,
                  style: widget.textTheme.labelSmall?.copyWith(
                    color: pc,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: pc.withOpacity(0.07),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.showSpeakerLabel ? 4 : 14),
                    topRight: const Radius.circular(16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                ),
                child: msg.isLoading
                    ? _MiniTypingIndicator(color: pc)
                    : msg.text.isEmpty
                    ? _MiniTypingIndicator(
                        color: pc,
                      ) // still streaming first token
                    : MarkdownBody(
                        data: msg.text,
                        styleSheet: MarkdownStyleSheet(
                          p: widget.textTheme.bodySmall?.copyWith(
                            color: widget.colors.onSurface.withOpacity(0.88),
                            height: 1.5,
                            fontSize: 13,
                          ),
                          strong: widget.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.colors.onSurface,
                            fontSize: 13,
                          ),
                          listBullet: widget.textTheme.bodySmall?.copyWith(
                            color: pc,
                            fontSize: 13,
                          ),
                          blockSpacing: 10,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINI TYPING INDICATOR
// ─────────────────────────────────────────────────────────────

class _MiniTypingIndicator extends StatefulWidget {
  const _MiniTypingIndicator({required this.color});
  final Color color;
  @override
  State<_MiniTypingIndicator> createState() => _MiniTypingIndicatorState();
}

class _MiniTypingIndicatorState extends State<_MiniTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (0.5 - (phase - 0.5).abs()) * 2;
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE SEPARATOR
// ─────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({
    required this.date,
    required this.colors,
    required this.textTheme,
  });
  final DateTime date;
  final ColorScheme colors;
  final TextTheme textTheme;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${_month(date.month)} ${date.day}';
  }

  String _month(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colors.onSurface.withOpacity(0.07),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colors.onSurface.withOpacity(0.07),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PERSONA PICKER SHEET
// ─────────────────────────────────────────────────────────────

class _PersonaPickerSheet extends StatefulWidget {
  const _PersonaPickerSheet({
    required this.currentPersona,
    required this.onSelect,
    required this.isChange,
  });
  final CounselorPersona currentPersona;
  final ValueChanged<CounselorPersona> onSelect;
  final bool isChange;
  @override
  State<_PersonaPickerSheet> createState() => _PersonaPickerSheetState();
}

class _PersonaPickerSheetState extends State<_PersonaPickerSheet> {
  late CounselorPersona _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.currentPersona;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            widget.isChange ? 'Switch Counselor' : 'Choose Your Counselor',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isChange
                ? "Switching loads that counselor's history."
                : 'Pick the style that fits you. Switch anytime.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ...CounselorPersona.values.map((persona) {
            final isSel = _selected == persona;
            final accent = persona.primary(brightness);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selected = persona),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSel
                        ? accent.withOpacity(0.08)
                        : colors.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSel ? accent : colors.outline.withOpacity(0.1),
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            persona.avatarAsset(brightness),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              persona.displayName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isSel ? accent : colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              persona.welcomeTagline,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withOpacity(0.45),
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSel)
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          color: accent,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelect(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selected.primary(brightness),
                foregroundColor: _selected.onPrimary(brightness),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.isChange
                    ? 'Switch to ${_selected.displayName}'
                    : 'Chat with ${_selected.displayName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
