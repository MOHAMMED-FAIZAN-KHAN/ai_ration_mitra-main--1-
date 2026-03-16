import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'models/grievance.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ration_provider.dart';
import 'providers/fps_provider.dart';
import 'providers/fps_operations_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/grievance_provider.dart';
import 'providers/admin_stock_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/gemini_ai_provider.dart';
import 'providers/gemini_assistant_provider.dart';
import 'providers/family_member_provider.dart';

import 'screens/auth/login_type_screen.dart';
import 'screens/auth/citizen_login_screen.dart';
import 'screens/auth/fps_login_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/citizen_register_screen.dart';
import 'screens/auth/fps_register_screen.dart';
import 'screens/auth/admin_register_screen.dart';
import 'screens/auth/otp_verification_screen.dart';

import 'screens/citizen/citizen_dashboard.dart';
import 'screens/citizen/profile_screen.dart';
import 'screens/citizen/edit_profile_screen.dart';
import 'screens/citizen/grievance_list_screen.dart';
import 'screens/citizen/grievance_form_screen.dart';
import 'screens/citizen/grievance_detail_screen.dart';
import 'screens/citizen/entitlement_screen.dart';
import 'screens/citizen/fps_locator.dart';
import 'screens/citizen/upcoming_distribution.dart';
import 'screens/citizen/notifications_screen.dart';

import 'screens/fps_dealer/fps_dashboard.dart';
import 'screens/fps_dealer/stock_management.dart';
import 'screens/fps_dealer/distribution_screen.dart';
import 'screens/fps_dealer/distribution_planner_screen.dart';
import 'screens/fps_dealer/beneficiary_scan.dart';
import 'screens/fps_dealer/dealer_profile_screen.dart';
import 'screens/fps_dealer/edit_dealer_profile_screen.dart';
import 'screens/fps_dealer/fps_notifications_screen.dart';
import 'screens/fps_dealer/beneficiary_registry_screen.dart';
import 'screens/fps_dealer/stock_requisition_screen.dart';
import 'screens/fps_dealer/dealer_grievance_list_screen.dart';

import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/fps_management.dart';
import 'screens/admin/alert_screen.dart';
import 'screens/admin/admin_profile_screen.dart';
import 'screens/admin/edit_admin_profile_screen.dart';
import 'screens/admin/admin_grievance_screen.dart';
import 'screens/admin/admin_stock_screen.dart';
import 'screens/admin/stock_detail_screen.dart';
import 'screens/admin/requisition_management_screen.dart';
import 'screens/admin/notification_creator_screen.dart';
import 'screens/admin/login_list_screen.dart';

import 'screens/chat/ai_assistant_screen.dart' as ai_assistant;
import 'screens/settings/settings_screen.dart';
import 'core/localization/app_localizations.dart';

const FirebaseOptions _androidFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCbe_-0pB14uhLmGSg5xG1kyogTQCBip_E',
  appId: '1:190475315373:android:8f2b2f44af56c14a9bfe24',
  messagingSenderId: '190475315373',
  projectId: 'ai-ration-mitra',
  storageBucket: 'ai-ration-mitra.firebasestorage.app',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  var firebaseEnabled = false;
  String? firebaseInitError;
  try {
    if (Firebase.apps.isEmpty) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await Firebase.initializeApp(options: _androidFirebaseOptions);
      } else {
        await Firebase.initializeApp();
      }
    }
    firebaseEnabled = true;
  } catch (e) {
    debugPrint('Firebase primary initialization failed: $e');
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      firebaseEnabled = true;
    } catch (fallbackError) {
      firebaseInitError = fallbackError.toString();
      debugPrint('Firebase initialization failed: $fallbackError');
    }
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Something went wrong. Please restart the app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ),
    );
  };

  runZonedGuarded(
    () {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(
                enableFirebase: firebaseEnabled,
                initializationError: firebaseInitError,
              ),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => RationProvider()),
            ChangeNotifierProvider(create: (_) => FPSProvider()),
            ChangeNotifierProvider(create: (_) => FPSOperationsProvider()),
            ChangeNotifierProvider(create: (_) => AdminProvider()),
            ChangeNotifierProvider(create: (_) => GrievanceProvider()),
            ChangeNotifierProvider(create: (_) => AdminStockProvider()),
            ChangeNotifierProvider(
                create: (_) =>
                    NotificationProvider(enableFirebase: firebaseEnabled)),
            ChangeNotifierProvider(create: (_) => GeminiAIProvider()),
            ChangeNotifierProvider(create: (_) => GeminiAssistantProvider()),
            ChangeNotifierProvider(create: (_) => FamilyMemberProvider()),
            // ChangeNotifierProvider(create: (_) => BookingProvider()),
            //  ChangeNotifierProvider(create: (_) => BookingProvider()),
          ],
          child: const AIRationMitra(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

class AIRationMitra extends StatelessWidget {
  const AIRationMitra({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'AI Ration Mitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: settingsProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          /// AUTH
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginTypeScreen());

          case '/citizen-login':
            return MaterialPageRoute(
                builder: (_) => const CitizenLoginScreen());

          case '/fps-login':
            return MaterialPageRoute(builder: (_) => const FPSLoginScreen());

          case '/admin-login':
            return MaterialPageRoute(builder: (_) => const AdminLoginScreen());

          case '/citizen-register':
            return MaterialPageRoute(
                builder: (_) => const CitizenRegisterScreen());

          case '/fps-register':
            return MaterialPageRoute(builder: (_) => const FPSRegisterScreen());

          case '/admin-register':
            return MaterialPageRoute(
                builder: (_) => const AdminRegisterScreen());

          case '/otp-verification':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                identifier: args['identifier'],
                userType: args['userType'],
                isRegistration: args['isRegistration'] ?? false,
              ),
            );

          /// CITIZEN
          case '/citizen-dashboard':
            return MaterialPageRoute(builder: (_) => const CitizenDashboard());

          case '/citizen/entitlement':
            return MaterialPageRoute(
                builder: (_) => const EntitlementsScreen());

          case '/citizen/fps-locator':
            return MaterialPageRoute(builder: (_) => const FpsLocatorScreen());

          case '/citizen/upcoming-distributions':
            return MaterialPageRoute(
                builder: (_) => const UpcomingDistributionPlanner());

          case '/citizen/notifications':
            return MaterialPageRoute(
              builder: (_) => const CitizenNotificationsScreen(),
            );

          case '/citizen/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());

          case '/citizen/edit-profile':
            return MaterialPageRoute(builder: (_) => const EditProfileScreen());

          case '/citizen/grievances':
            return MaterialPageRoute(
                builder: (_) => const GrievanceListScreen());

          case '/citizen/grievance-form':
            return MaterialPageRoute(
                builder: (_) => const GrievanceFormScreen());

          case '/citizen/grievance-detail':
            if (settings.arguments is! Grievance) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Error: Invalid grievance')),
                ),
              );
            }
            final grievance = settings.arguments as Grievance;
            return MaterialPageRoute(
              builder: (_) => GrievanceDetailScreen(grievance: grievance),
            );

          /// FPS DEALER
          case '/fps-dashboard':
            return MaterialPageRoute(builder: (_) => const FPSDashboard());

          case '/fps/stock':
            return MaterialPageRoute(builder: (_) => const StockManagement());

          case '/fps/distribution':
            return MaterialPageRoute(
                builder: (_) => const DistributionScreen());

          case '/fps/distribution-planner':
            return MaterialPageRoute(
              builder: (_) => const DistributionPlannerScreen(),
            );

          case '/fps/scan':
            return MaterialPageRoute(builder: (_) => const BeneficiaryScan());

          case '/fps/beneficiaries':
            return MaterialPageRoute(
              builder: (_) => const BeneficiaryRegistryScreen(),
            );

          case '/fps/notifications':
            return MaterialPageRoute(
              builder: (_) => const FPSNotificationsScreen(),
            );

          case '/fps/stock-requisition':
            return MaterialPageRoute(
              builder: (_) => const StockRequisitionScreen(),
            );

          case '/fps/grievances':
            return MaterialPageRoute(
              builder: (_) => const DealerGrievanceListScreen(),
            );

          case '/fps/profile':
            return MaterialPageRoute(
                builder: (_) => const DealerProfileScreen());

          case '/fps/edit-profile':
            return MaterialPageRoute(
                builder: (_) => const EditDealerProfileScreen());

          /// ADMIN
          case '/admin-dashboard':
            return MaterialPageRoute(builder: (_) => const AdminDashboard());

          case '/admin/fps-management':
            return MaterialPageRoute(builder: (_) => const FPSManagement());

          case '/admin/alerts':
            return MaterialPageRoute(builder: (_) => const AlertsScreen());

          case '/admin/profile':
            return MaterialPageRoute(
                builder: (_) => const AdminProfileScreen());

          case '/admin/edit-profile':
            return MaterialPageRoute(
                builder: (_) => const EditAdminProfileScreen());

          case '/admin/grievances':
            return MaterialPageRoute(
                builder: (_) => const AdminGrievanceScreen());

          case '/admin/requisitions':
            return MaterialPageRoute(
              builder: (_) => const RequisitionManagementScreen(),
            );

          case '/admin/stock':
            return MaterialPageRoute(builder: (_) => const AdminStockScreen());

          case '/admin/creator':
            return MaterialPageRoute(
              builder: (_) => const NotificationCreatorScreen(),
            );

          case '/admin/login-lists':
            return MaterialPageRoute(builder: (_) => const LoginListScreen());

          case '/admin/stock-detail':
            final itemName = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => StockDetailScreen(itemName: itemName),
            );

          /// AI ASSISTANT
          case '/ai-assistant':
            return MaterialPageRoute(
              builder: (_) => const ai_assistant.AIAssistantScreen(),
            );

          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());

          default:
            return MaterialPageRoute(builder: (_) => const LoginTypeScreen());
        }
      },
    );
  }
}
