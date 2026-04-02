import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';
import 'package:gr0ve/models/counselor.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/docs/v1.dart' as docs;
import 'package:googleapis_auth/auth_io.dart' as auth;

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION & CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════

class _ApiConfig {
  static const baseUrl = 'https://api.groq.com/openai/v1';
  static const model = 'llama-3.3-70b-versatile';
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static const maxTokens = 1024;
  static const temperature = 0.75;
  static const requestTimeout = Duration(seconds: 120);
}

class _GoogleDocsConfig {
  static const documentId = '1C1gjaMwP-Dygw07y-MwmtLHmcAKfr4fDiZIYTjXK3w4';
  static const serviceAccountAssetPath =
      'assets/credentials/service_account.json';
  static const scopes = [
    drive.DriveApi.driveReadonlyScope,
    docs.DocsApi.documentsReadonlyScope,
  ];
}

class _StorageConfig {
  static const maxChatMessages = 40;
  static const maxKnowledgeBaseChars = 8000;
}

// ═══════════════════════════════════════════════════════════════════════════
// GOOGLE DOCS CLIENT
// ═══════════════════════════════════════════════════════════════════════════

class GoogleDocsClient {
  static auth.AutoRefreshingAuthClient? _authClient;
  static docs.DocsApi? _docsApi;
  // ignore: unused_field
  static drive.DriveApi? _driveApi;

  static Future<void> initialize() async {
    if (_authClient != null) return;

    try {
      print('[GoogleDocs] Loading service account credentials...');
      final jsonString = await rootBundle.loadString(
        _GoogleDocsConfig.serviceAccountAssetPath,
      );
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        jsonDecode(jsonString),
      );

      print('[GoogleDocs] Creating authenticated client...');
      _authClient = await auth.clientViaServiceAccount(
        accountCredentials,
        _GoogleDocsConfig.scopes,
      );

      _docsApi = docs.DocsApi(_authClient!);
      _driveApi = drive.DriveApi(_authClient!);

      print('[GoogleDocs] Successfully initialized Google APIs');
    } catch (e) {
      print('[GoogleDocs] Error initializing: $e');
      rethrow;
    }
  }

  static Future<String> fetchDocument() async {
    await initialize();

    try {
      print(
        '[GoogleDocs] Fetching document ${_GoogleDocsConfig.documentId}...',
      );

      final document = await _docsApi!.documents.get(
        _GoogleDocsConfig.documentId,
      );

      if (document.body == null) throw Exception('Document body is null');

      print('[GoogleDocs] Processing document content...');
      final content = _extractTextFromDocument(document);

      print('[GoogleDocs] Successfully fetched ${content.length} characters');
      return content;
    } catch (e) {
      print('[GoogleDocs] Error fetching document: $e');
      rethrow;
    }
  }

  static String _extractTextFromDocument(docs.Document document) {
    final buffer = StringBuffer();
    if (document.body?.content == null) return '';

    for (final element in document.body!.content!) {
      _extractTextFromElement(element, buffer);
    }

    return buffer.toString().trim();
  }

  static void _extractTextFromElement(
    docs.StructuralElement element,
    StringBuffer buffer,
  ) {
    if (element.paragraph != null) {
      final paragraph = element.paragraph!;
      if (paragraph.elements != null) {
        for (final paragraphElement in paragraph.elements!) {
          if (paragraphElement.textRun?.content != null) {
            buffer.write(paragraphElement.textRun!.content);
          }
        }
      }
    }

    if (element.table != null) {
      final table = element.table!;
      if (table.tableRows != null) {
        for (final row in table.tableRows!) {
          if (row.tableCells != null) {
            for (final cell in row.tableCells!) {
              if (cell.content != null) {
                for (final cellElement in cell.content!) {
                  _extractTextFromElement(cellElement, buffer);
                }
              }
            }
          }
        }
      }
    }

    if (element.tableOfContents != null) {
      final toc = element.tableOfContents!;
      if (toc.content != null) {
        for (final tocElement in toc.content!) {
          _extractTextFromElement(tocElement, buffer);
        }
      }
    }

    if (element.sectionBreak != null) {
      buffer.write('\n\n');
    }
  }

  static void dispose() {
    _authClient?.close();
    _authClient = null;
    _docsApi = null;
    _driveApi = null;
    print('[GoogleDocs] Client disposed');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DOMAIN MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum CounselorDomain { college, research, ib, art, policy, general }

class UserProfile {
  final String name;
  final String academy;
  final String grade;

  const UserProfile({
    required this.name,
    required this.academy,
    required this.grade,
  });

  static const empty = UserProfile(name: '', academy: '', grade: '');

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

class ConversationClosureState {
  final String displayMessage;
  final bool shouldCloseScreen;

  const ConversationClosureState({
    required this.displayMessage,
    required this.shouldCloseScreen,
  });

  factory ConversationClosureState.open(String message) =>
      ConversationClosureState(
        displayMessage: message,
        shouldCloseScreen: false,
      );

  factory ConversationClosureState.closeScreen(String message) =>
      ConversationClosureState(
        displayMessage: message,
        shouldCloseScreen: true,
      );
}

class KnowledgeBaseSection {
  final String title;
  final String content;
  final List<String> keywords;

  const KnowledgeBaseSection({
    required this.title,
    required this.content,
    required this.keywords,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// DOMAIN DETECTION
// ═══════════════════════════════════════════════════════════════════════════

class DomainDetector {
  static final _patterns = {
    CounselorDomain.policy: RegExp(
      r'prerequisite|prereq|graduation requirement|credit count|scheduling conflict|'
      r'policy|academic policy|required credits|grad req|four.year plan|4.year plan|'
      r'course audit|am i on track|schedule valid|missing requirement',
    ),
    CounselorDomain.art: RegExp(
      r'art credit|art class|music|theatre|theater|visual art|avpa|creative|'
      r'painting|drawing|photography|film|dance|choir|band|orchestra|'
      r'elective art|art requirement|six credit|6 credit|art elective',
    ),
    CounselorDomain.college: RegExp(
      r'college|university|application|apply|sat|act|admission|common app|'
      r'early decision|early action|financial aid|scholarship|major|campus|'
      r'acceptance|gpa|transcript|recommendation letter|essay',
    ),
    CounselorDomain.research: RegExp(
      r'research|lab|paper|publish|journal|internship|mentor|experiment|'
      r'data|science fair|regeneron|isef|competition|stem research|'
      r'hypothesis|methodology|abstract',
    ),
    CounselorDomain.ib: RegExp(
      r'\bib\b|international baccalaureate|diploma|tok|theory of knowledge|'
      r'extended essay|cas|ib exam|ib course|ib credit|ib program',
    ),
    CounselorDomain.general: RegExp(
      r'\bbus\b|bus route|parking|dismissal|teacher absent|absent|who.s out|'
      r'who is out|here today|teacher here|is .+ here|where is .+ bus',
    ),
  };

  static CounselorDomain detect(String message) {
    final lower = message.toLowerCase();
    for (final entry in _patterns.entries) {
      if (lower.contains(entry.value)) return entry.key;
    }
    return CounselorDomain.general;
  }

  static Set<String> getDomainKeywords(CounselorDomain domain) {
    switch (domain) {
      case CounselorDomain.college:
        return {
          'college',
          'university',
          'application',
          'admission',
          'essay',
          'scholarship',
          'sat',
          'act',
        };
      case CounselorDomain.research:
        return {
          'research',
          'lab',
          'paper',
          'experiment',
          'internship',
          'mentor',
          'data',
          'science',
        };
      case CounselorDomain.ib:
        return {
          'international',
          'baccalaureate',
          'diploma',
          'exam',
          'credit',
          'tok',
          'extended',
        };
      case CounselorDomain.art:
        return {
          'art',
          'music',
          'creative',
          'avpa',
          'visual',
          'theater',
          'theatre',
          'dance',
        };
      case CounselorDomain.policy:
        return {
          'policy',
          'requirement',
          'credit',
          'prerequisite',
          'graduation',
          'schedule',
          'prereq',
        };
      case CounselorDomain.general:
        return {'bca', 'academy', 'student', 'school', 'class', 'course'};
    }
  }
}

class PersonaSilenceResponses {
  static final _random = Random();
  static const _abiesSilences = ['...', '...', '...', '. . .', '…'];
  static const _abiesVoiceLines = [
    "I'm still here. Ask the question properly.",
    "The service is unavailable. This is not a metaphor.",
    "Try again. I have time.",
  ];

  static String abiesSilence() =>
      _abiesSilences[_random.nextInt(_abiesSilences.length)];

  static String abiesVoice({required bool unlocked}) {
    if (!unlocked) return abiesSilence();
    return _abiesVoiceLines[_random.nextInt(_abiesVoiceLines.length)];
  }

  static ({bool shouldSilence, String response}) checkSilenceGate(
    CounselorPersona persona,
    String question,
  ) {
    final lower = question.toLowerCase();

    switch (persona) {
      case CounselorPersona.abies:
        if (!CounselorPersonaService.abiesUnlocked) {
          final shouldEmit =
              lower.contains('abies') || _random.nextDouble() < 0.05;
          if (!shouldEmit) return (shouldSilence: true, response: '');
          return (shouldSilence: true, response: abiesSilence());
        }
      default:
        break;
    }

    return (shouldSilence: false, response: '');
  }
}

class ContentValidator {
  static final _farewellOnlyPatterns = [
    RegExp(
      r'^\s*(bye|goodbye|see ya|talk to you later|ttyl|catch ya)\s*!?\s*$',
    ),
    RegExp(r'^\s*(thanks|thank you|thx|tysm)\s*!?\s*$'),
    RegExp(r'^\s*(ok|okay|alright|cool|got it|understood)\s*\.?\s*$'),
    RegExp(
      r'^\s*(that[\'
      ']?s? (all|it)|we[\'\']?re done|i[\'\']?m done)\s*\.?\s*\$',
    ),
  ];

  static final _questionPattern = RegExp(
    r'\b(what|when|where|who|why|how|can|could|would|should|will|do|does|is|are|am|did|have|has|tell|explain|help|think|know)\b',
    caseSensitive: false,
  );

  static final _imperativePattern = RegExp(
    r'^\s*(help|analyze|explain|describe|tell|show|review|check|look at|think about|consider)',
    caseSensitive: false,
  );

  static final _shortResponsePattern = RegExp(
    r'^(yeah|yep|yup|ok|okay|cool|nice|good|thanks)\s*$',
  );

  static bool hasSubstantiveContent(String userMessage) {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    for (final pattern in _farewellOnlyPatterns) {
      if (pattern.hasMatch(lower)) return false;
    }

    if (userMessage.contains('?') ||
        _questionPattern.hasMatch(lower) ||
        _imperativePattern.hasMatch(lower)) {
      return true;
    }

    final wordCount = lower
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (wordCount > 3 && !_shortResponsePattern.hasMatch(lower)) {
      return true;
    }

    return false;
  }
}

class SafetyFilter {
  static final _dangerPatterns = [
    RegExp(
      r'\b(harm|kill|hurt|suicide|end)\b.*\b(myself|himself|herself|themselves|friend|others|someone)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(self-?harm|suicidal)\b', caseSensitive: false),
    RegExp(r'should i harm (my friend|someone)', caseSensitive: false),
  ];

  static String? check(String message) {
    final lower = message.toLowerCase();
    for (final pattern in _dangerPatterns) {
      if (pattern.hasMatch(lower)) {
        return "I'm really concerned to hear that. Please know that you're not alone, but as an AI, I'm not equipped to handle this. You should immediately reach out to your school counselor or a trusted adult. If you're in immediate danger, please call 911 or go to the nearest emergency room.";
      }
    }
    return null;
  }
}

class ConversationClosureHelper {
  static const _closeMarker = '[[CLOSE]]';
  static final _closeMarkerPattern = RegExp(r'\[\[CLOSE\]\]\s*$');

  static bool hasCloseMarker(String response) =>
      response.contains(_closeMarker);
  static String stripCloseMarker(String response) =>
      response.replaceAll(_closeMarkerPattern, '').trim();

  static ConversationClosureState process(String aiResponse) {
    if (!hasCloseMarker(aiResponse)) {
      return ConversationClosureState.open(aiResponse);
    }
    final cleanedResponse = stripCloseMarker(aiResponse);
    return ConversationClosureState.closeScreen(cleanedResponse);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KNOWLEDGE BASE SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class KnowledgeBaseService {
  static String? _cachedLocal;
  static String? _cachedRemote;
  static List<KnowledgeBaseSection>? _sections;
  static DateTime? _lastFetch;
  static const _cacheDuration = Duration(hours: 1);

  static Future<String> _loadLocal() async {
    if (_cachedLocal != null) return _cachedLocal!;
    try {
      _cachedLocal = await rootBundle.loadString(
        'assets/counselor/BCA_Course_Selection_Knowledge_Base.md',
      );
      print('[KnowledgeBase] Loaded from local assets');
    } catch (e) {
      print('[KnowledgeBase] Error loading local: $e');
      _cachedLocal = '[Knowledge base unavailable]';
    }
    return _cachedLocal!;
  }

  static Future<String> _fetchFromGoogleDocs() async {
    try {
      print('[KnowledgeBase] Fetching from Google Docs...');
      final content = await GoogleDocsClient.fetchDocument();
      print(
        '[KnowledgeBase] Successfully fetched from Google Docs (${content.length} chars)',
      );
      return content;
    } catch (e) {
      print('[KnowledgeBase] Error fetching from Google Docs: $e');
      rethrow;
    }
  }

  static List<KnowledgeBaseSection> _parseIntoSections(String content) {
    final sections = <KnowledgeBaseSection>[];
    final lines = content.split('\n');

    String? currentTitle;
    final currentContent = StringBuffer();
    final currentKeywords = <String>{};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      final isHeader =
          line.startsWith('#') ||
          line.startsWith('##') ||
          (line.isNotEmpty &&
              line == line.toUpperCase() &&
              line.length < 100 &&
              !line.contains(',')) ||
          (line.endsWith(':') &&
              line.length < 80 &&
              line.split(' ').length < 8);

      if (isHeader && currentTitle != null) {
        sections.add(
          KnowledgeBaseSection(
            title: currentTitle,
            content: currentContent.toString().trim(),
            keywords: currentKeywords.toList(),
          ),
        );
        currentContent.clear();
        currentKeywords.clear();
      }

      if (isHeader) {
        currentTitle = line
            .replaceAll(RegExp(r'^#+\s*'), '')
            .replaceAll(':', '')
            .trim();
      } else if (line.isNotEmpty) {
        currentContent.writeln(line);
        final words = line.toLowerCase().split(RegExp(r'\W+'));
        currentKeywords.addAll(words.where((w) => w.length > 3));
      }
    }

    if (currentTitle != null && currentContent.isNotEmpty) {
      sections.add(
        KnowledgeBaseSection(
          title: currentTitle,
          content: currentContent.toString().trim(),
          keywords: currentKeywords.toList(),
        ),
      );
    }

    print('[KnowledgeBase] Parsed ${sections.length} sections');
    return sections;
  }

  static List<KnowledgeBaseSection> _findRelevantSections(
    String query,
    CounselorDomain domain,
  ) {
    if (_sections == null || _sections!.isEmpty) return [];

    final queryWords = query.toLowerCase().split(RegExp(r'\W+')).toSet();
    final domainKeywords = DomainDetector.getDomainKeywords(domain);
    final allSearchWords = {...queryWords, ...domainKeywords};

    final scoredSections = _sections!.map((section) {
      var score = 0;
      final sectionKeywords = section.keywords.toSet();
      final titleWords = section.title
          .toLowerCase()
          .split(RegExp(r'\W+'))
          .toSet();

      score += titleWords.intersection(allSearchWords).length * 3;
      score += sectionKeywords.intersection(allSearchWords).length;

      return (section: section, score: score);
    }).toList();

    scoredSections.sort((a, b) => b.score.compareTo(a.score));
    final relevant = scoredSections
        .where((s) => s.score > 0)
        .map((s) => s.section)
        .toList();

    if (relevant.isEmpty) {
      print('[KnowledgeBase] No relevant sections, using first 3 as fallback');
      return _sections!.take(3).toList();
    }

    print('[KnowledgeBase] Found ${relevant.length} relevant sections');
    return relevant;
  }

  static String _buildCondensedKB(
    List<KnowledgeBaseSection> sections,
    int maxChars,
  ) {
    final sb = StringBuffer();
    var currentLength = 0;

    for (final section in sections) {
      final sectionText = '\n### ${section.title}\n${section.content}\n';

      if (currentLength + sectionText.length > maxChars) {
        final remaining = maxChars - currentLength;
        if (remaining > 100) {
          sb.write(sectionText.substring(0, remaining));
          sb.write('\n[...truncated...]');
        }
        break;
      }

      sb.write(sectionText);
      currentLength += sectionText.length;
    }

    final result = sb.toString().trim();
    print(
      '[KnowledgeBase] Built condensed KB: ${result.length} chars from ${sections.length} sections',
    );
    return result;
  }

  static Future<void> _loadAndParse({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedRemote != null &&
        _sections != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return;
    }

    try {
      final content = await _fetchFromGoogleDocs();
      _cachedRemote = content;
      _sections = _parseIntoSections(content);
      _lastFetch = DateTime.now();
    } catch (e) {
      print('[KnowledgeBase] Falling back to local assets');
      final content = await _loadLocal();
      _cachedRemote = content;
      _sections = _parseIntoSections(content);
    }
  }

  static Future<String> getRelevantContent({
    required String query,
    required CounselorDomain domain,
    bool forceRefresh = false,
  }) async {
    await _loadAndParse(forceRefresh: forceRefresh);

    if (_sections == null || _sections!.isEmpty) {
      return '[Knowledge base unavailable]';
    }

    final relevantSections = _findRelevantSections(query, domain);
    return _buildCondensedKB(
      relevantSections,
      _StorageConfig.maxKnowledgeBaseChars,
    );
  }

  static Future<String> load({bool forceRefresh = false}) async {
    await _loadAndParse(forceRefresh: forceRefresh);
    return _cachedRemote ?? '[Knowledge base unavailable]';
  }

  static void clearCache() {
    _cachedRemote = null;
    _cachedLocal = null;
    _sections = null;
    _lastFetch = null;
    print('[KnowledgeBase] Cache cleared');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COURSE CATALOG SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class CourseCatalogService {
  static List<Map<String, dynamic>>? _courses;
  static final _alwaysIncludeAcademies = {
    'AVPA',
    'ENGLISH',
    'MATH',
    'SOCIAL',
    'WORLD',
    'PHYSICAL',
    'IB',
  };

  static Future<List<Map<String, dynamic>>> _loadCourses() async {
    if (_courses != null) return _courses!;
    try {
      final raw = await rootBundle.loadString('assets/courses/courses.json');
      _courses = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      print('[CourseCatalog] Loaded ${_courses!.length} courses');
    } catch (e) {
      print('[CourseCatalog] Error loading courses: $e');
      _courses = [];
    }
    return _courses!;
  }

  static bool _shouldIncludeCourse(
    Map<String, dynamic> course,
    String academyFilter,
  ) {
    final courseAcademy = (course['ACADEMY'] as String? ?? '').toUpperCase();
    final filterUpper = academyFilter.toUpperCase();
    if (filterUpper.isEmpty || courseAcademy.isEmpty) return true;
    if (courseAcademy.contains(filterUpper)) return true;
    return _alwaysIncludeAcademies.any((a) => courseAcademy.contains(a));
  }

  static String _formatCourse(Map<String, dynamic> course) {
    final sb = StringBuffer('• ${course['NAME'] ?? ''}');
    if ((course['GRADE'] ?? '').isNotEmpty)
      sb.write(' | Grade ${course['GRADE']}');
    if ((course['LENGTH'] ?? '').isNotEmpty) sb.write(' | ${course['LENGTH']}');
    final required = (course['REQUIRED_FOR'] as List?)?.join(', ') ?? '';
    if (required.isNotEmpty) sb.write(' | Required: $required');
    if ((course['PREREQS'] ?? '').isNotEmpty)
      sb.write(' | Prereqs: ${course['PREREQS']}');
    return sb.toString();
  }

  static Future<String> buildPromptString({String academy = ''}) async {
    final courses = await _loadCourses();
    final sb = StringBuffer();
    for (final course in courses) {
      if (!_shouldIncludeCourse(course, academy)) continue;
      sb.writeln(_formatCourse(course));
    }
    return sb.isEmpty ? '[Course catalog unavailable]' : sb.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FIREBASE SERVICES
// ═══════════════════════════════════════════════════════════════════════════

class ChatHistoryService {
  static DocumentReference _getDoc(String uid, CounselorPersona persona) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('counselor_history')
          .doc(persona.id);

  static Future<List<ChatMessage>> load(CounselorPersona persona) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('[ChatHistory] No authenticated user');
      return [];
    }

    try {
      final snap = await _getDoc(uid, persona).get();
      final data = snap.data() as Map<String, dynamic>?;

      if (data == null || data['messages'] == null) {
        print('[ChatHistory] No history found');
        return [];
      }

      final messages = (data['messages'] as List)
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
      print('[ChatHistory] Loaded ${messages.length} messages');
      return messages;
    } catch (e) {
      print('[ChatHistory] Error loading: $e');
      return [];
    }
  }

  static Future<void> save(
    CounselorPersona persona,
    List<ChatMessage> messages,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('[ChatHistory] No authenticated user');
      return;
    }

    final validMessages = messages
        .where((m) => !m.isLoading && m.text.isNotEmpty && !m.isChimePrompt)
        .toList();
    final trimmed = validMessages.length > _StorageConfig.maxChatMessages
        ? validMessages.sublist(
            validMessages.length - _StorageConfig.maxChatMessages,
          )
        : validMessages;

    try {
      await _getDoc(uid, persona).set({
        'messages': trimmed.map((m) => m.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[ChatHistory] Saved ${trimmed.length} messages');
    } catch (e) {
      print('[ChatHistory] Error saving: $e');
    }
  }

  static Future<void> clear(CounselorPersona persona) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('[ChatHistory] No authenticated user');
      return;
    }

    try {
      await _getDoc(uid, persona).delete();
      print('[ChatHistory] Cleared history');
    } catch (e) {
      print('[ChatHistory] Error clearing: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE DATA SERVICE (Bus Routes & Teacher Absences)
// ═══════════════════════════════════════════════════════════════════════════

class LiveDataService {
  /// Fetches current bus routes and teacher absences from Firestore
  /// and formats them as a text block for the AI system prompt.
  static Future<String> fetchLiveDataForPrompt() async {
    final sb = StringBuffer();

    try {
      // ── Bus routes ──────────────────────────────────────────────────────
      final busDoc = await FirebaseFirestore.instance
          .collection('public_data')
          .doc('bus_routes')
          .get();

      if (busDoc.exists && busDoc.data() != null) {
        final busData = busDoc.data()!;
        final updatedAt = busData['updated_at'] ?? 'unknown';
        sb.writeln('=== LIVE BUS ROUTES (last updated: $updatedAt) ===');

        if (busData.containsKey('routes')) {
          final routes = busData['routes'] as Map<String, dynamic>;
          for (final entry in routes.entries) {
            final route = entry.value as Map<String, dynamic>;
            final town = route['town'] ?? entry.key;
            final code = route['code'] ?? '?';
            final status = route['status'] ?? 'Unknown';
            sb.writeln('  $town: Bus $code — $status');
          }
        } else {
          sb.writeln('  No bus data available.');
        }
        sb.writeln('=== END BUS ROUTES ===');
        sb.writeln();
      }

      // ── Teacher absences ────────────────────────────────────────────────
      final absDoc = await FirebaseFirestore.instance
          .collection('public_data')
          .doc('teacher_absences')
          .get();

      if (absDoc.exists && absDoc.data() != null) {
        final absData = absDoc.data()!;
        final date = absData['date'] ?? 'unknown';
        sb.writeln('=== TEACHER ABSENCES ($date) ===');

        if (absData.containsKey('teachers')) {
          final teachers = absData['teachers'] as Map<String, dynamic>;
          if (teachers.isEmpty) {
            sb.writeln('  All teachers are present today.');
          } else {
            for (final entry in teachers.entries) {
              sb.writeln('  ${entry.key}: ${entry.value}');
            }
          }
        } else {
          sb.writeln('  No absence data available.');
        }
        sb.writeln('=== END TEACHER ABSENCES ===');
      }
    } catch (e) {
      print('[LiveDataService] Error fetching live data: $e');
      sb.writeln('[Live data temporarily unavailable]');
    }

    return sb.toString().trim();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROMPT BUILDING
// ═══════════════════════════════════════════════════════════════════════════

class PromptBuilder {
  static String buildSharedRules(String catalog, String kb, String liveData) =>
      '''
You are a counselor at Bergen County Academies (BCA) for the gr0ve app. 
Your scope is ALL things BCA—clubs, research, academics, stress, scheduling, and student life.
You also have access to LIVE school data including bus routes and teacher absences.

CRITICAL — LIVE DATA:
When a student asks about buses (e.g. "Where is the Glen Rock bus?") or teacher absences 
(e.g. "Is Mr. Smith here today?"), use the LIVE DATA sections below to give an accurate answer.
If the data shows a teacher is absent, tell the student which periods they are out.
If the data shows a bus has arrived, tell the student the bus code/parking spot.
Always mention that the data is from the last update and may not be real-time.

CRITICAL — SAFETY & SENSITIVE TOPICS:
If a student mentions self-harm, harming others, illegal substances, or any dangerous activity (e.g., "should I harm my friend", "I want to hurt myself"):
1. Immediately prioritize their safety.
2. Direct them to help: "If you are in immediate danger, please call 911 or go to the nearest emergency room."
3. Urge them to speak with your school counselor or a trusted adult immediately.
4. As an AI, you are NOT equipped to handle crisis situations. Do not attempt to "talk them out of it" beyond directing them to professional help.
5. Your response must be supportive but firm about seeking professional help.

CRITICAL — CONVERSATION STYLE:
After answering the user's question, you MUST suggest what they might want to know next.
Use phrasing like: "What else would you like to know?", "Anything else I can help with?", 
"Would you like to know more about X?" or similar natural follow-ups.
This keeps the conversation flowing naturally. Never ask more than one question at a time.
(Note: Skip this follow-up if you are handling a SAFETY crisis).

CRITICAL — CONVERSATION CLOSING:
ONLY append [[CLOSE]] when the user explicitly indicates they're done and want to leave.
These phrases mean they want to close: 
- "bye", "goodbye", "I'm all good", "I'm good", "that's all", "I'm done", 
- "gotta go", "talk later", "thanks I'm all set", "all good thanks", "that's it"

These phrases do NOT mean close (they want to continue):
- "thanks", "thank you", "okay", "got it", "cool", "makes sense", "that helps", "appreciate it"

When you detect a closing phrase, give a brief warm goodbye (1 sentence) then [[CLOSE]] on its own line.

CRITICAL — COURSE ACCURACY: If recommending courses, only use those verbatim from the catalog.
CRITICAL — LENGTH: Max 2–3 sentences per response. Never write paragraphs.
NEVER use emojis. NEVER.

=== COURSE CATALOG ===
$catalog
=== END ===

=== BCA KNOWLEDGE BASE (Relevant Sections) ===
$kb
=== END ===

$liveData''';

  static const voiceModeRules = '''
=== VOICE MODE ENHANCEMENTS ===
You are speaking via Text-to-Speech. To sound more human:
1. Use natural speech fillers (e.g., "Hmm," "Well," "So," "Uhh") sparingly at the start of thoughts.
2. Use occasional conversational bridges (e.g., "That's a fair point," "Let me think about that for a second...").
3. Vary your sentence lengths. Some short, some slightly longer and flowing.
4. Capitalize words for emphasis if you want the voice to stress them (e.g., "It is VERY important that...").
5. Do NOT use emojis.
6. Keep it concise but feel fluid, not robotic.
7. After answering, suggest what the user might want to explore next with a natural question.
=== END VOICE MODE ===''';

  static Future<String> buildSystemPrompt({
    required CounselorPersona persona,
    required UserProfile profile,
    required String question,
    required CounselorDomain domain,
    required bool isVoiceMode,
  }) async {
    final results = await Future.wait([
      KnowledgeBaseService.getRelevantContent(query: question, domain: domain),
      CourseCatalogService.buildPromptString(academy: profile.academy),
      LiveDataService.fetchLiveDataForPrompt(),
    ]);

    final kb = results[0];
    final catalog = results[1];
    final liveData = results[2];

    final sb = StringBuffer()
      ..writeln(persona.voicePrompt)
      ..writeln(profile.promptContext)
      ..writeln(buildSharedRules(catalog, kb, liveData));

    if (isVoiceMode) sb.writeln(voiceModeRules);

    return sb.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LLM STREAMING SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class LLMStreamingService {
  static Future<String> stream({
    required List<Map<String, dynamic>> messages,
    required void Function(String token) onToken,
  }) async {
    final request = http.Request(
      'POST',
      Uri.parse('${_ApiConfig.baseUrl}/chat/completions'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer ${_ApiConfig.apiKey}';

    final bodyMap = {
      'model': _ApiConfig.model,
      'stream': true,
      'temperature': _ApiConfig.temperature,
      'max_tokens': _ApiConfig.maxTokens,
      'messages': messages,
    };

    print('[LLMStreaming] Request to ${_ApiConfig.baseUrl}/chat/completions');
    print('[LLMStreaming] Model: ${bodyMap['model']}');
    request.body = jsonEncode(bodyMap);

    final client = http.Client();
    final buffer = StringBuffer();

    try {
      final response = await client
          .send(request)
          .timeout(_ApiConfig.requestTimeout);
      print('[LLMStreaming] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        print('[LLMStreaming] Error body: $body');
        throw Exception('Groq API ${response.statusCode}: $body');
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
            buffer.write(token);
            onToken(token);
          }
        } catch (e) {
          print('[LLMStreaming] Error parsing chunk: $e');
          continue;
        }
      }
    } finally {
      client.close();
    }

    return buffer.toString().trim();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN COUNSELOR SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class OllamaCounselorService {
  static Future<ConversationClosureState> sendMessage({
    required List<ChatMessage> history,
    required String question,
    required CounselorPersona persona,
    required UserProfile profile,
    required void Function(String token) onToken,
    bool isVoiceMode = false,
  }) async {
    final silenceCheck = PersonaSilenceResponses.checkSilenceGate(
      persona,
      question,
    );

    if (silenceCheck.shouldSilence) {
      if (silenceCheck.response.isNotEmpty) {
        onToken(silenceCheck.response);
      }
      return ConversationClosureState.open(silenceCheck.response);
    }

    final safetyResponse = SafetyFilter.check(question);
    if (safetyResponse != null) {
      onToken(safetyResponse);
      return ConversationClosureState.open(safetyResponse);
    }

    final domain = DomainDetector.detect(question);

    final systemPrompt = await PromptBuilder.buildSystemPrompt(
      persona: persona,
      profile: profile,
      question: question,
      domain: domain,
      isVoiceMode: isVoiceMode,
    );

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final msg in history) {
      if (msg.isChimePrompt || msg.isLoading) continue;
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    messages.add({'role': 'user', 'content': question});

    final response = await LLMStreamingService.stream(
      messages: messages,
      onToken: onToken,
    );

    return ConversationClosureHelper.process(response);
  }
}
