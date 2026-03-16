import 'package:flutter/foundation.dart';
import '../services/gemini_ai_service.dart';
import '../models/user.dart';
import 'ai_support_knowledge.dart';

class GeminiAssistantReply {
  final String text;
  final String? suggestedRoute;
  final List<String> steps;
  final bool fromGemini;

  const GeminiAssistantReply({
    required this.text,
    this.suggestedRoute,
    this.steps = const [],
    this.fromGemini = true,
  });
}

class GeminiAIAssistantService {
  final GeminiAIService _geminiService = GeminiAIService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _geminiService.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Gemini AI Assistant: $e');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Build the system prompt with app knowledge
  String _buildSystemPrompt(UserType? userType) {
    final userTypeStr = userType?.toString().split('.').last ?? 'citizen';

    return '''You are an expert AI Assistant for the "AI Ration Mitra" public distribution system app. Your role is to help users solve problems, answer questions, and provide step-by-step guidance.

USER TYPE: $userTypeStr

ABOUT THE APP:
- AI Ration Mitra is a digital public distribution system app
- It helps citizens check rations, find FPS dealers, submit grievances, and track distributions
- FPS dealers can manage stock, scan beneficiaries, and process distributions
- Admins can manage FPS dealers, handle grievances, manage stock, and send notifications

APP MODULES & FEATURES BY USER TYPE:

=== CITIZEN FEATURES ===
1. Entitlements - View monthly ration allocation by commodity
   - Path: /citizen/entitlement
   - Shows available rations and allocation
   
2. Grievance System - Submit and track complaints
   - Path: /citizen/grievance-form
   - Types: Distribution issues, Quality complaints, Eligibility concerns
   
3. FPS Locator - Find nearest Fair Price Shop
   - Path: /citizen/fps-locator
   - Shows GPS location, distance, hours
   
4. Upcoming Distribution - Track distribution schedules
   - Path: /citizen/upcoming-distributions
   - Shows when, where, what items
   
5. Notifications - Receive updates about distributions and grievances
   - Path: /citizen/notifications
   - Alerts about ration availability, grievance status
   
6. Profile Management
   - Show/edit personal details
   - Display QR code for verification at FPS

=== FPS DEALER FEATURES ===
1. Stock Management - Manage commodity inventory
   - Add/remove stock
   - Track consumption
   
2. Distribution - Process ration distributions
   - Scan beneficiary QR
   - Mark items distributed
   - Update stock
   
3. Beneficiary Registry - Manage customer list
   - Add/remove beneficiaries
   - Verify eligibility
   
4. Stock Requisition - Request stock from admin
   - Specify required commodities
   - Track request status

=== ADMIN FEATURES ===
1. FPS Management - Manage dealer accounts
   - Create/edit/delete FPS dealers
   - Assign locations
   
2. Stock Management - Distribute stock to FPS dealers
   - Allocate commodities
   - Track inventory
   
3. Grievance Management - Review and resolve complaints
   - View details of grievances
   - Send resolution messages
   - Track status

RESPONSE GUIDELINES:
1. Always be helpful and friendly
2. Provide clear, numbered step-by-step instructions
3. When applicable, suggest the relevant app route
4. For issues:
   - Ask clarifying questions
   - Suggest troubleshooting steps
   - Provide direct path to the feature
5. If the user describes steps, validate and suggest improvements
6. Use simple, clear language
7. Break complex tasks into smaller steps
8. End with "Is there anything else I can help you with?"

COMMON ISSUES & SOLUTIONS:
- Data not syncing: Try pull-to-refresh or restart the app
- Profile issues: Verify all required fields are filled, check internet
- Grievance not submitted: Check all mandatory fields, try again
- Distribution not showing: Ensure location is set correctly
- FPS not visible: Verify GPS is enabled, refresh the list''';
  }

  /// Format support entries as context for Gemini
  String _buildKnowledgeContext() {
    final buffer = StringBuffer();
    buffer.writeln('\nAPP KNOWLEDGE BASE:\n');

    final groupedByType = <String, List<SupportEntry>>{};
    for (final entry in supportEntries) {
      final type = entry.id.split('_').first;
      groupedByType.putIfAbsent(type, () => []).add(entry);
    }

    for (final entry in groupedByType.values.expand((e) => e)) {
      buffer.writeln('- ${entry.title}');
      buffer.writeln('  Keywords: ${entry.keywords.join(", ")}');
      buffer.writeln('  Answer: ${entry.answer}');
      if (entry.route != null) {
        buffer.writeln('  Direct Link: ${entry.route}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate AI response with step-by-step guidance
  Future<GeminiAssistantReply> getAssistantResponse(
    String userMessage, {
    UserType? userType,
    String? userName,
    String? userId,
  }) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Assistant is not initialized. Call initialize() first.');
    }

    try {
      // Find related support entries to provide context
      final relatedEntries = _findRelatedEntries(userMessage, userType);

      // Build comprehensive prompt
      final systemPrompt = _buildSystemPrompt(userType);
      final knowledgeContext = _buildKnowledgeContext();

      // Build user context
      final userContext = '''User: ${userName ?? 'User'}
Type: ${userType?.toString().split('.').last ?? 'unknown'}
Query: $userMessage

${relatedEntries.isNotEmpty ? 'Related Topics from Knowledge Base:\n' + relatedEntries.map((e) => '- ${e.title}: ${e.answer}').join('\n') : ''}

Please provide:
1. A helpful response to the user's question
2. If applicable, numbered step-by-step instructions
3. If a specific feature is relevant, mention the feature name
4. Always end with asking if they need more help''';

      final fullPrompt = '''$systemPrompt

$knowledgeContext

User Query:
$userContext''';

      // Get response from Gemini
      final response = await _geminiService.generateText(fullPrompt);

      if (response == null || response.isEmpty) {
        return GeminiAssistantReply(
          text: 'I had trouble generating a response. Please try again.',
          fromGemini: false,
        );
      }

      // Extract suggested route if mentioned
      String? suggestedRoute;
      for (final entry in supportEntries) {
        if (response.toLowerCase().contains(entry.title.toLowerCase()) &&
            entry.route != null) {
          suggestedRoute = entry.route;
          break;
        }
      }

      // Extract steps from response
      final steps = _extractSteps(response);

      return GeminiAssistantReply(
        text: response,
        suggestedRoute: suggestedRoute,
        steps: steps,
        fromGemini: true,
      );
    } catch (e) {
      debugPrint('Error getting Gemini response: $e');
      rethrow;
    }
  }

  /// Find support entries related to user query
  List<SupportEntry> _findRelatedEntries(String query, UserType? userType) {
    final queryLower = query.toLowerCase();
    return supportEntries.where((entry) {
      // Check keywords
      final keywordMatch =
          entry.keywords.any((kw) => queryLower.contains(kw.toLowerCase()));

      // Check sample questions
      final questionMatch = entry.sampleQuestions
          .any((q) => queryLower.contains(q.toLowerCase()));

      // Check if user type matches
      final userTypePrefix = userType?.toString().split('.').last ?? 'citizen';
      final typeMatch = entry.id.startsWith(userTypePrefix);

      return keywordMatch || questionMatch || typeMatch;
    }).toList();
  }

  /// Extract numbered steps from response
  List<String> _extractSteps(String response) {
    final steps = <String>[];
    final lines = response.split('\n');

    for (final line in lines) {
      // Match lines like "1. Step description", "2) Step description", etc.
      final match = RegExp(r'^(\d+)[.\)]\s+(.+)$').firstMatch(line.trim());
      if (match != null) {
        steps.add(match.group(2) ?? '');
      }
    }

    return steps;
  }

  /// Stream response for long-running generation
  Future<Stream<String>?> getAssistantResponseStream(
    String userMessage, {
    UserType? userType,
    String? userName,
  }) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Assistant is not initialized. Call initialize() first.');
    }

    try {
      final systemPrompt = _buildSystemPrompt(userType);
      final knowledgeContext = _buildKnowledgeContext();

      final fullPrompt = '''$systemPrompt

$knowledgeContext

User Query:
User: ${userName ?? 'User'}
Query: $userMessage

Please provide a helpful response with step-by-step instructions if applicable.''';

      return await _geminiService.generateTextStream(fullPrompt);
    } catch (e) {
      debugPrint('Error getting Gemini stream: $e');
      return null;
    }
  }

  /// Troubleshoot specific issues
  Future<String?> troubleshootIssue(
    String issueDescription, {
    String? featureName,
    UserType? userType,
  }) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Assistant is not initialized. Call initialize() first.');
    }

    try {
      final troubleshootPrompt =
          '''You are a troubleshooting expert for the AI Ration Mitra app.

A user is experiencing this issue:
"$issueDescription"

${featureName != null ? 'Feature involved: $featureName' : ''}
User type: ${userType?.toString().split('.').last ?? 'unknown'}

Provide:
1. Likely causes (numbered list)
2. Step-by-step troubleshooting guide
3. When to contact support

Be concise and practical.''';

      return await _geminiService.generateText(troubleshootPrompt);
    } catch (e) {
      debugPrint('Error troubleshooting issue: $e');
      return null;
    }
  }

  /// Generate FAQ content
  Future<String?> generateFAQ(String topic) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Assistant is not initialized. Call initialize() first.');
    }

    try {
      final faqPrompt =
          '''Generate 5 frequently asked questions and answers about "$topic" in the AI Ration Mitra app.

Format:
Q1: [Question]
A1: [Answer with steps if applicable]

Q2: [Question]
A2: [Answer with steps if applicable]

...and so on.

Keep answers concise and practical.''';

      return await _geminiService.generateText(faqPrompt);
    } catch (e) {
      debugPrint('Error generating FAQ: $e');
      return null;
    }
  }
}
