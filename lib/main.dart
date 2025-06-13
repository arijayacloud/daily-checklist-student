import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';

// Laravel API providers
import '/laravel_api/providers/api_provider.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/notification_provider.dart';
import '/laravel_api/providers/user_provider.dart';
import '/laravel_api/providers/checklist_provider.dart';

// Screens
import '/screens/auth/login_screen.dart';
import '/screens/auth/teacher_register_screen.dart';
import '/screens/parents/add_parent_screen.dart';
import '/screens/splash_screen.dart';
import '/screens/progress/child_checklist_screen.dart';
import '/lib/theme/app_theme.dart';

// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await initializeDateFormatting(AppConfig.defaultLocale, null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Base API provider
        ChangeNotifierProvider(create: (_) => ApiProvider()),
        
        // Auth provider using the API provider
        ChangeNotifierProxyProvider<ApiProvider, AuthProvider>(
          create: (context) => AuthProvider(Provider.of<ApiProvider>(context, listen: false)),
          update: (context, api, previous) => previous ?? AuthProvider(api),
        ),
        
        // User provider
        ChangeNotifierProxyProvider2<ApiProvider, AuthProvider, UserProvider>(
          create: (context) => UserProvider(
            Provider.of<ApiProvider>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, api, auth, previous) => 
            previous ?? UserProvider(api, auth),
        ),
        
        // Child provider
        ChangeNotifierProxyProvider2<ApiProvider, AuthProvider, ChildProvider>(
          create: (context) => ChildProvider(
            Provider.of<ApiProvider>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, api, auth, previous) => 
            previous ?? ChildProvider(api, auth),
        ),
        
        // Activity provider
        ChangeNotifierProxyProvider2<ApiProvider, AuthProvider, ActivityProvider>(
          create: (context) => ActivityProvider(
            Provider.of<ApiProvider>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, api, auth, previous) => 
            previous ?? ActivityProvider(api, auth),
        ),
        
        // Planning provider
        ChangeNotifierProxyProvider2<ApiProvider, AuthProvider, PlanningProvider>(
          create: (context) => PlanningProvider(
            Provider.of<ApiProvider>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, api, auth, previous) => 
            previous ?? PlanningProvider(api, auth),
        ),
        
        // Notification provider
        ChangeNotifierProxyProvider2<ApiProvider, AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<ApiProvider>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, api, auth, previous) => 
            previous ?? NotificationProvider(api, auth),
        ),
        
        // Checklist provider
        ChangeNotifierProxyProvider<ApiProvider, ChecklistProvider>(
          create: (context) => ChecklistProvider(Provider.of<ApiProvider>(context, listen: false)),
          update: (context, api, previous) => previous ?? ChecklistProvider(api),
        ),
        
        // FCM Service provider
        Provider<FCMService>(
          create: (_) => FCMService(
            onNotificationTap: (data) {
              // Handle notification taps here
              print('Notification tapped with data: $data');
              // Navigate based on notification type if needed
              if (data.containsKey('type')) {
                // Example: Navigate to specific screen based on notification type
                String type = data['type'];
                switch (type) {
                  case 'new_plan':
                    // Handle plan notification
                    break;
                  case 'activity_completed':
                    // Handle activity notification
                    break;
                  default:
                    // Handle other notification types
                    break;
                }
              }
            },
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Initialize FCM Service after providers are ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
              Provider.of<FCMService>(context, listen: false).initialize(context);
            }
            
            // Listen to auth state changes to initialize/clean up FCM
            Provider.of<AuthProvider>(context, listen: false).addListener(() {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isAuthenticated) {
                Provider.of<FCMService>(context, listen: false).initialize(context);
              }
            });
          });
          
          return _buildMaterialApp();
        },
      ),
    );
  }
  
  // Common Material App configuration
  Widget _buildMaterialApp() {
    return MaterialApp(
      title: 'TK Activity Checklist',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/add-parent': (context) => const AddParentScreen(),
        TeacherRegisterScreen.routeName:
            (context) => const TeacherRegisterScreen(),
        ChildChecklistScreen.routeName:
            (context) => const ChildChecklistScreen(),
      },
    );
  }
}
