import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/screens/signin_signup.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('Firebase initialization error: $e');
    print('Stack trace: $stackTrace');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ryde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const SigninSignup(),
      builder: (context, widget) {
        // Global error boundary
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          print('Widget Error: ${errorDetails.exception}');
          print('Stack trace: ${errorDetails.stack}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Something went wrong'),
                  SizedBox(height: 8),
                  Text('Please restart the app', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        };
        return widget ?? Container();
      },
    );
  }
}

