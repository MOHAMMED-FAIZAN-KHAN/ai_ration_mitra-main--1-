import 'ai_support_knowledge.dart';

class SupportMatch {
  final SupportEntry entry;
  final double score;
  final String? suggestion;

  const SupportMatch({
    required this.entry,
    required this.score,
    this.suggestion,
  });
}

class SupportMatcher {
  static SupportMatch? match(String query, List<SupportEntry> entries) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return null;
    }

    SupportMatch? best;
    for (final entry in entries) {
      final score = _scoreEntry(normalizedQuery, entry);
      if (best == null || score > best.score) {
        best = SupportMatch(
          entry: entry,
          score: score,
          suggestion: _bestQuestion(normalizedQuery, entry),
        );
      }
    }
    return best;
  }

  static double _scoreEntry(String query, SupportEntry entry) {
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) {
      return 0;
    }

    final keywordTokens = <String>{};
    for (final keyword in entry.keywords) {
      keywordTokens.addAll(_tokenize(_normalize(keyword)));
    }

    final overlap =
        queryTokens.intersection(keywordTokens).length / queryTokens.length;

    var bestSimilarity = 0.0;
    for (final question in entry.sampleQuestions) {
      final sim =
          _similarity(query, _normalize(question)).clamp(0.0, 1.0).toDouble();
      if (sim > bestSimilarity) {
        bestSimilarity = sim;
      }
    }

    return (overlap * 0.55) + (bestSimilarity * 0.45);
  }

  static String? _bestQuestion(String query, SupportEntry entry) {
    String? best;
    var bestScore = 0.0;
    for (final question in entry.sampleQuestions) {
      final score = _similarity(query, _normalize(question));
      if (score > bestScore) {
        bestScore = score;
        best = question;
      }
    }
    return best;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Set<String> _tokenize(String input) {
    return input.split(' ').where((token) => token.isNotEmpty).toSet();
  }

  static double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) {
      return 0;
    }
    final distance = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) {
      return 0;
    }
    return 1 - (distance / maxLen);
  }

  static int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;
    if (m == 0) return n;
    if (n == 0) return m;

    final List<int> prev = List<int>.generate(n + 1, (i) => i);
    final List<int> curr = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        final deletion = prev[j] + 1;
        final insertion = curr[j - 1] + 1;
        final substitution = prev[j - 1] + cost;
        curr[j] = _min3(deletion, insertion, substitution);
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[n];
  }

  static int _min3(int a, int b, int c) {
    var min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }
}
