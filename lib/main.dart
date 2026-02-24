import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'src/login_screen.dart';
import 'src/complete_profile_screen.dart';
import 'home_screen.dart'; // ← el HomeScreen nuevo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urabá Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF97316)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Conectando con Firebase
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(
              color: Color(0xFFF97316),
            )),
          );
        }

        // Usuario logueado → verificar perfil
        if (authSnapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                      child: CircularProgressIndicator(
                    color: Color(0xFFF97316),
                  )),
                );
              }

              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;

              // Perfil incompleto → CompleteProfileScreen
              if (!userSnapshot.hasData ||
                  !userSnapshot.data!.exists ||
                  userData == null ||
                  userData['perfilCompleto'] != true) {
                return const CompleteProfileScreen();
              }

              // Perfil completo → HomeScreen nuevo
              return const HomeScreen();
            },
          );
        }

        // Sin sesión → LoginScreen
        return const LoginScreen();
      },
    );
  }
}
