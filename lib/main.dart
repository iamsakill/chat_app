import 'package:chat_app/services.dart/auth_services.dart';
import 'package:chat_app/services.dart/database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "YOUR_API_KEY",
        appId: "YOUR_APP_ID",
        messagingSenderId: "YOUR_SENDER_ID",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().userStream,
          initialData: null,
        ),
        Provider(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        title: 'WhatsApp Clone',
        theme: ThemeData(
          primaryColor: const Color(0xFF075E54),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF075E54),
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF128C7E),
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF128C7E),
          ),
        ),
        home: const AuthenticationWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) => HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final isLoading = context.select<AuthService, bool>(
      (auth) => auth.isLoading,
    );

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return user == null ? AuthScreen() : HomeScreen();
  }
}
