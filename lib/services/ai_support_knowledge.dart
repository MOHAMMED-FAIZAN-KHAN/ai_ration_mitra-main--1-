class SupportEntry {
  final String id;
  final String title;
  final String answer;
  final String? route;
  final List<String> keywords;
  final List<String> sampleQuestions;

  const SupportEntry({
    required this.id,
    required this.title,
    required this.answer,
    required this.keywords,
    required this.sampleQuestions,
    this.route,
  });
}

const List<SupportEntry> supportEntries = <SupportEntry>[
  SupportEntry(
    id: 'citizen_dashboard',
    title: 'Citizen Dashboard Overview',
    route: '/citizen-dashboard',
    keywords: <String>[
      'citizen dashboard',
      'home',
      'quick actions',
      'overview',
    ],
    sampleQuestions: <String>[
      'how to use citizen dashboard',
      'what is on the citizen home screen',
      'citizen quick actions',
    ],
    answer:
        'Citizen Dashboard:\n1. Open Citizen Dashboard after login.\n2. Use quick cards for entitlements, grievances, notifications, and FPS locator.\n3. Check upcoming distribution status on the top cards.\n4. Tap any card to open the relevant module.',
  ),
  SupportEntry(
    id: 'citizen_entitlements',
    title: 'Check Entitlements',
    route: '/citizen/entitlement',
    keywords: <String>[
      'entitlement',
      'allocation',
      'ration',
      'monthly allocation',
    ],
    sampleQuestions: <String>[
      'how to check entitlements',
      'see monthly ration allocation',
      'entitlement not visible',
    ],
    answer:
        'Entitlements:\n1. Open Entitlements from the Citizen dashboard.\n2. Review monthly allocation by commodity.\n3. If items look missing, pull-to-refresh and confirm your profile category.',
  ),
  SupportEntry(
    id: 'citizen_profile_update',
    title: 'Update Citizen Profile',
    route: '/citizen/edit-profile',
    keywords: <String>[
      'edit profile',
      'update profile',
      'citizen profile',
      'email',
      'phone',
    ],
    sampleQuestions: <String>[
      'how to edit citizen profile',
      'update profile details',
      'profile not saving',
    ],
    answer:
        'Edit Profile:\n1. Go to Profile.\n2. Tap Edit Profile.\n3. Update details and Save.\n4. Reopen Profile to confirm the changes synced.',
  ),
  SupportEntry(
    id: 'citizen_qr',
    title: 'Profile QR Verification',
    route: '/citizen/profile',
    keywords: <String>[
      'qr',
      'verification',
      'profile qr',
      'scan',
    ],
    sampleQuestions: <String>[
      'where is profile qr',
      'how to show qr for verification',
    ],
    answer:
        'Profile QR:\n1. Open Profile.\n2. Show the QR section for verification.\n3. FPS dealer can scan this QR during distribution.',
  ),
  SupportEntry(
    id: 'citizen_grievance_submit',
    title: 'Submit Grievance',
    route: '/citizen/grievance-form',
    keywords: <String>[
      'grievance',
      'complaint',
      'issue submit',
      'raise complaint',
    ],
    sampleQuestions: <String>[
      'how to submit a grievance',
      'raise complaint in app',
      'grievance form',
    ],
    answer:
        'Submit Grievance:\n1. Open Grievances.\n2. Tap Add/Submit.\n3. Enter title and description.\n4. Submit and track status from the list.',
  ),
  SupportEntry(
    id: 'grievance_status',
    title: 'Grievance Status Tracking',
    route: '/citizen/grievances',
    keywords: <String>[
      'grievance status',
      'pending',
      'resolved',
      'rejected',
      'in progress',
    ],
    sampleQuestions: <String>[
      'how to track grievance status',
      'grievance pending or resolved meaning',
    ],
    answer:
        'Grievance Status:\n1. Open Grievances.\n2. Tap a grievance to view status and remarks.\n3. Status can be Pending, In Progress, Resolved, or Rejected.',
  ),
  SupportEntry(
    id: 'citizen_notifications',
    title: 'Notifications',
    route: '/citizen/notifications',
    keywords: <String>[
      'notifications',
      'alert',
      'notice',
      'unread',
    ],
    sampleQuestions: <String>[
      'how to see notifications',
      'notification not showing',
    ],
    answer:
        'Notifications:\n1. Open Notifications from the dashboard bell icon.\n2. Use filters to see unread.\n3. Tap a notification to view details.',
  ),
  SupportEntry(
    id: 'fps_locator',
    title: 'FPS Locator',
    route: '/citizen/fps-locator',
    keywords: <String>[
      'fps locator',
      'shop location',
      'map',
      'nearby shop',
    ],
    sampleQuestions: <String>[
      'find nearest fps shop',
      'fps shop location',
      'map not showing',
    ],
    answer:
        'FPS Locator:\n1. Open FPS Locator.\n2. Allow location permission.\n3. Search or select a shop to view details.',
  ),
  SupportEntry(
    id: 'upcoming_distribution',
    title: 'Upcoming Distribution',
    route: '/citizen/upcoming-distributions',
    keywords: <String>[
      'upcoming distribution',
      'calendar',
      'distribution date',
    ],
    sampleQuestions: <String>[
      'next ration distribution date',
      'upcoming distribution calendar',
    ],
    answer:
        'Upcoming Distribution:\n1. Open Upcoming Distributions.\n2. Select a date to view allocations.\n3. Today and Tomorrow statuses show automatically.',
  ),
  SupportEntry(
    id: 'fps_scan',
    title: 'FPS Scan & Distribution',
    route: '/fps/scan',
    keywords: <String>[
      'fps scan',
      'distribution',
      'verify beneficiary',
      'fps dealer',
    ],
    sampleQuestions: <String>[
      'how to scan beneficiary',
      'fps distribution steps',
      'dealer scan not working',
    ],
    answer:
        'FPS Distribution:\n1. Open FPS Scan.\n2. Scan QR or enter beneficiary ID.\n3. Verify eligibility.\n4. Complete distribution and update stock.',
  ),
  SupportEntry(
    id: 'fps_stock',
    title: 'FPS Stock Management',
    route: '/fps/stock',
    keywords: <String>[
      'fps stock',
      'stock update',
      'inventory',
    ],
    sampleQuestions: <String>[
      'how to update fps stock',
      'stock not updating',
    ],
    answer:
        'FPS Stock:\n1. Open FPS Stock.\n2. Review available inventory.\n3. After distribution, verify stock decrement.\n4. If mismatch, refresh and re-check.',
  ),
  SupportEntry(
    id: 'fps_requisition',
    title: 'FPS Stock Requisition',
    route: '/fps/stock-requisition',
    keywords: <String>[
      'requisition',
      'request stock',
      'fps requisition',
    ],
    sampleQuestions: <String>[
      'how to raise stock requisition',
      'fps requisition steps',
    ],
    answer:
        'Stock Requisition:\n1. Open Stock Requisition.\n2. Enter required quantities.\n3. Submit request for admin approval.',
  ),
  SupportEntry(
    id: 'fps_grievance',
    title: 'FPS Dealer Grievance',
    route: '/fps/grievances',
    keywords: <String>[
      'fps grievance',
      'dealer complaint',
      'operational issue',
    ],
    sampleQuestions: <String>[
      'fps dealer grievance',
      'complaint by dealer',
    ],
    answer:
        'FPS Grievance:\n1. Open FPS Grievances.\n2. Submit dealer issue.\n3. Track status from the list.',
  ),
  SupportEntry(
    id: 'admin_dashboard',
    title: 'Admin Dashboard',
    route: '/admin-dashboard',
    keywords: <String>[
      'admin dashboard',
      'kpi',
      'admin home',
    ],
    sampleQuestions: <String>[
      'admin dashboard overview',
      'admin home screen',
    ],
    answer:
        'Admin Dashboard:\n1. Review KPI cards for stock, grievances, and alerts.\n2. Tap cards to open detailed management screens.',
  ),
  SupportEntry(
    id: 'admin_grievances',
    title: 'Admin Grievance Management',
    route: '/admin/grievances',
    keywords: <String>[
      'admin grievances',
      'resolve grievance',
      'remarks',
    ],
    sampleQuestions: <String>[
      'how to resolve grievance',
      'admin grievance inbox',
    ],
    answer:
        'Admin Grievances:\n1. Open Admin Grievances.\n2. Select a grievance.\n3. Update status and add remarks.\n4. Save to notify the user.',
  ),
  SupportEntry(
    id: 'admin_stock_alerts',
    title: 'Admin Stock & Alerts',
    route: '/admin/alerts',
    keywords: <String>[
      'admin stock',
      'alerts',
      'critical stock',
    ],
    sampleQuestions: <String>[
      'stock alerts in admin',
      'critical stock list',
    ],
    answer:
        'Admin Alerts:\n1. Open Alerts to view critical stock.\n2. Review low-stock FPS shops.\n3. Trigger follow-up or requisition review.',
  ),
  SupportEntry(
    id: 'admin_requisitions',
    title: 'Admin Requisitions',
    route: '/admin/requisitions',
    keywords: <String>[
      'admin requisitions',
      'approve request',
      'reject request',
    ],
    sampleQuestions: <String>[
      'how to approve requisition',
      'admin requisition flow',
    ],
    answer:
        'Admin Requisitions:\n1. Open Requisitions.\n2. Review FPS stock requests.\n3. Approve or reject and add comments.',
  ),
  SupportEntry(
    id: 'login_otp_issue',
    title: 'Login / OTP Issues',
    route: '/otp-verification',
    keywords: <String>[
      'otp',
      'login issue',
      'cannot login',
      'verification code',
    ],
    sampleQuestions: <String>[
      'otp not received',
      'login failed',
      'cannot login to app',
    ],
    answer:
        'Login / OTP Troubleshoot:\n1. Confirm internet connectivity.\n2. Retry OTP request.\n3. Check that phone number or email is correct.\n4. If still failing, log out and try again.',
  ),
  SupportEntry(
    id: 'location_permission',
    title: 'Location Permission',
    route: '/citizen/fps-locator',
    keywords: <String>[
      'location permission',
      'gps',
      'permission denied',
    ],
    sampleQuestions: <String>[
      'location permission denied',
      'fps locator not working',
    ],
    answer:
        'Location Permission:\n1. Allow location permission when prompted.\n2. If denied, open device settings and enable location for the app.\n3. Re-open FPS Locator.',
  ),
  SupportEntry(
    id: 'apk_checklist',
    title: 'APK Release Checklist',
    keywords: <String>[
      'apk',
      'release',
      'build',
      'checklist',
    ],
    sampleQuestions: <String>[
      'apk checklist',
      'release build steps',
    ],
    answer:
        'APK Release Checklist:\n1. Run flutter pub get.\n2. Run flutter analyze.\n3. Run flutter test.\n4. Validate key routes and flows.\n5. Build: flutter build apk --release.\n6. Test on real devices.',
  ),
];
