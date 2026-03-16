class ApiService {
  // Placeholder for future backend integration.
  // For now this acts as an offline knowledge source for the AI assistant.

  static const List<Map<String, String>> supportKnowledge =
      <Map<String, String>>[
    <String, String>{
      'topic': 'citizen_profile',
      'content':
          'Open Profile tab to view UID, category, mobile, assigned shop and location. Use Edit Profile to update and save.',
    },
    <String, String>{
      'topic': 'grievance_tracking',
      'content':
          'Go to Grievances, submit complaint, and track status as Pending, In Progress, Resolved, or Rejected.',
    },
    <String, String>{
      'topic': 'fps_scan',
      'content':
          'FPS dealer can verify beneficiary using scan/ID entry, check eligibility, and complete ration distribution.',
    },
    <String, String>{
      'topic': 'admin_actions',
      'content':
          'Admin can monitor stock, review alerts, process requisitions, and resolve citizen/FPS grievances.',
    },
    <String, String>{
      'topic': 'apk_readiness',
      'content':
          'Before APK build: run flutter pub get, flutter analyze, flutter test, and verify all key routes and login flows.',
    },
  ];

  String? getKnowledgeByTopic(String topic) {
    for (final item in supportKnowledge) {
      if (item['topic'] == topic) {
        return item['content'];
      }
    }
    return null;
  }
}

