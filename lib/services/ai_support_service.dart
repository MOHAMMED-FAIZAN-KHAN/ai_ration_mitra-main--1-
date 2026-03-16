import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'ai_support_knowledge.dart';
import 'ai_support_matcher.dart';

class AssistantReply {
  final String text;
  final String? route;
  final String? suggestion;
  final bool fromOnline;
  final String? matchedEntryId;

  const AssistantReply({
    required this.text,
    this.route,
    this.suggestion,
    this.fromOnline = false,
    this.matchedEntryId,
  });
}

class AiSupportService {
  AiSupportService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const String _functionUrl =
      'https://us-central1-ai-ration-mitra.cloudfunctions.net/aiAssist';
  static const String _learnedKey = 'ai_learned_map';

  final http.Client _client;
  Map<String, String> _learned = <String, String>{};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_learnedKey);
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _learned = decoded.map((key, value) => MapEntry(key, '$value'));
      }
    }
    _loaded = true;
  }

  Future<void> rememberMapping(String query, SupportEntry entry) async {
    await _ensureLoaded();
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return;
    }
    _learned[normalized] = entry.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_learnedKey, jsonEncode(_learned));
  }

  Future<AssistantReply> reply(
    String input, {
    UserType? userType,
    String? userId,
  }) async {
    await _ensureLoaded();
    final normalized = _normalize(input);

    final learnedEntryId = _learned[normalized];
    if (learnedEntryId != null) {
      final entry = supportEntries
          .firstWhere((item) => item.id == learnedEntryId, orElse: () {
        return supportEntries.first;
      });
      return AssistantReply(
        text: entry.answer,
        route: entry.route,
        matchedEntryId: entry.id,
      );
    }

    final match = SupportMatcher.match(input, supportEntries);
    if (match != null && match.score >= 0.6) {
      return AssistantReply(
        text: match.entry.answer,
        route: match.entry.route,
        matchedEntryId: match.entry.id,
      );
    }

    final suggestion =
        match != null && match.score >= 0.35 ? match.suggestion : null;
    final hintedEntry = match?.entry;
    final online = await _askOnline(
      input,
      userType: userType,
      userId: userId,
      hint: hintedEntry,
    );

    if (online != null && online.trim().isNotEmpty) {
      return AssistantReply(
        text: online.trim(),
        route: hintedEntry?.route,
        suggestion: suggestion,
        fromOnline: true,
        matchedEntryId: hintedEntry?.id,
      );
    }

    if (match != null) {
      return AssistantReply(
        text: match.entry.answer,
        route: match.entry.route,
        suggestion: suggestion,
        matchedEntryId: match.entry.id,
      );
    }

    return AssistantReply(
      text:
          'I can help if you phrase it like:\n- teach me <module>\n- diagnose <problem>\n- how to use <feature>\n- apk checklist',
      suggestion: suggestion,
    );
  }

  Future<String?> _askOnline(
    String message, {
    UserType? userType,
    String? userId,
    SupportEntry? hint,
  }) async {
    try {
      final payload = <String, dynamic>{
        'message': message,
        'userType': userType?.name,
        'userId': userId,
        'hint': hint == null
            ? null
            : <String, dynamic>{
                'title': hint.title,
                'answer': hint.answer,
                'route': hint.route,
                'keywords': hint.keywords,
              },
      };

      final response = await _client.post(
        Uri.parse(_functionUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['reply'] is String) {
        return decoded['reply'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
