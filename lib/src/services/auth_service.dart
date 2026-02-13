import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Rate limiting: registrar intentos fallidos
  final Map<String, List<DateTime>> _failedAttempts = {};
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream para escuchar cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verificar si el usuario está bloqueado por rate limiting
  bool _isLockedOut(String email) {
    if (!_failedAttempts.containsKey(email)) return false;

    final attempts = _failedAttempts[email]!;
    final recentAttempts = attempts
        .where((time) => DateTime.now().difference(time) < _lockoutDuration)
        .toList();

    if (recentAttempts.length >= _maxAttempts) {
      return true;
    }

    // Limpiar intentos antiguos
    _failedAttempts[email] = recentAttempts;
    return false;
  }

  // Registrar intento fallido
  void _recordFailedAttempt(String email) {
    if (!_failedAttempts.containsKey(email)) {
      _failedAttempts[email] = [];
    }
    _failedAttempts[email]!.add(DateTime.now());
  }

  // Limpiar intentos fallidos
  void _clearFailedAttempts(String email) {
    _failedAttempts.remove(email);
  }

  // 1. Login con Email/Password
  Future<String?> login(String email, String password) async {
    try {
      // Verificar si está bloqueado por rate limiting
      if (_isLockedOut(email)) {
        return 'Demasiados intentos fallidos. Intenta de nuevo en 15 minutos.';
      }

      final userCred =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      _clearFailedAttempts(email);

      // Optionally sync user data after login
      if (userCred.user != null) {
        await _firestoreService.saveUser(userCred.user!);
      }

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      _recordFailedAttempt(email);

      switch (e.code) {
        case 'user-not-found':
          return 'No existe usuario con ese correo.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'invalid-email':
          return 'Correo inválido.';
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Intenta de nuevo más tarde.';
        default:
          return 'Error de autenticación: ${e.message}';
      }
    } catch (e) {
      _recordFailedAttempt(email);
      return 'Error inesperado. Por favor intenta de nuevo.';
    }
  }

  // 2. Registro con Email/Password
  Future<String?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Creamos/actualizamos el documento en Firestore inmediatamente después de registrarse
      if (credential.user != null) {
        await _firestoreService.saveUser(credential.user!);
      }

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      }
      if (e.code == 'email-already-in-use') {
        return 'Este correo ya está registrado.';
      }
      if (e.code == 'invalid-email') {
        return 'Correo inválido.';
      }
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // 3. Login con Google ✅
  Future<String?> loginWithGoogle() async {
    try {
      // A. Iniciar flujo de Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Si el usuario cancela
      if (googleUser == null) {
        return 'Inicio de sesión cancelado';
      }

      // B. Obtener credenciales de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // C. Crear credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // D. Iniciar sesión en Firebase
      final userCred = await _auth.signInWithCredential(credential);

      // Sincronizamos con Firestore
      if (userCred.user != null) {
        await _firestoreService.saveUser(userCred.user!);
      }

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      return 'Error de autenticación: ${e.message}';
    } catch (e) {
      return 'Error al iniciar sesión con Google. Por favor intenta de nuevo.';
    }
  }

  // 4. Logout
  Future<void> logout() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }
}
