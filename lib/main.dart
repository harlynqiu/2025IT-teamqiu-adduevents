import 'package:firebase_core/firebase_core.dart'; // Import the firebase_core package
import 'package:adduevents/src/views/public/login.dart'; // Your Login Screen
import 'package:flutter/material.dart';

// Firebase config for web
const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyAjwU7MCdRt-P5IKueaSUO6nNFLWv73KFs", // Replace with your API key
  authDomain: "ateneo-events.firebaseapp.com", // Replace with your auth domain
  projectId: "ateneo-events", // Replace with your project ID
  storageBucket: "ateneo-events.appspot.com", // <-- Fixed here
  messagingSenderId: "686786977221", // Replace with your messaging sender ID
  appId: "1:686786977221:web:d49a3703a512c645967fac", // Replace with your app ID
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(options: firebaseConfig); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
