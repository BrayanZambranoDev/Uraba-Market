import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_service.dart';
import 'register_screen.dart';
import 'complete_profile_screen.dart';

import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';

const String _kBackgroundUrl = 'assets/images/login_bg.jpg';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ConnectivityService _connectivityService = ConnectivityService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isConnected = true;
  bool _showSuccessAnimation = false;

  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF0DF220);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkConnectivity();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkConnectivity() {
    _connectivityService.checkConnectivity().then((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isConnected) {
      _showMessage('Sin conexión a internet. Por favor verifica tu conexión.',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final error = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      await _onAuthSuccess(FirebaseAuth.instance.currentUser,
          fromGoogle: false);
    } else {
      _showMessage(error, isError: true);
    }
  }

  void _handleGoogleLogin() async {
    if (!_isConnected) {
      _showMessage('Sin conexión a internet. Por favor verifica tu conexión.',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final error = await _authService.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      await _onAuthSuccess(FirebaseAuth.instance.currentUser, fromGoogle: true);
    } else if (error != 'Inicio de sesión cancelado') {
      _showMessage(error, isError: true);
    }
  }

  void _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      _showMessage('Por favor ingresa un correo válido en el campo de arriba',
          isError: true);
      return;
    }
    if (!_isConnected) {
      _showMessage('Sin conexión a internet. Por favor verifica tu conexión.',
          isError: true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Text('¿Enviar instrucciones de recuperación a:\n\n$email?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('✅ Revisa tu correo ($email) para restablecer tu contraseña',
          isError: false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(
        e.code == 'user-not-found'
            ? 'No existe una cuenta con ese correo'
            : 'Error al enviar correo. Por favor intenta de nuevo.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Error inesperado. Por favor intenta de nuevo.',
          isError: true);
    }
  }

  void _handleBiometric() async {
    setState(() => _isLoading = true);
    final result = await _authService.loginWithBiometrics();
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage(result ?? 'Biometría no disponible', isError: true);
  }

  Future<void> _onAuthSuccess(User? user, {bool fromGoogle = false}) async {
    if (user != null) await _firestoreService.saveUser(user);
    if (!mounted) return;
    setState(() => _showSuccessAnimation = true);
    await Future.delayed(const Duration(milliseconds: 1400));
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _connectivityService.isConnected,
      builder: (context, snapshot) {
        if (snapshot.hasData) _isConnected = snapshot.data ?? true;
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    _buildHero(),
                    Expanded(child: _buildForm()),
                  ]),
                ),
              ),
            ),
            if (_showSuccessAnimation)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Lottie.network(
                        'https://assets2.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                        repeat: false,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.33,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Stack(children: [
            Image.asset(_kBackgroundUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFED7AA), Color(0xFFFB923C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    )),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Colors.transparent,
                      Colors.white,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ]),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.eco_rounded, color: _orange, size: 17),
                      const SizedBox(width: 6),
                      Text('Urabá Market',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF1E293B))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -28,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                      color: _orange.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.agriculture_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isConnected) _buildConnectivityBanner(),

          Column(children: [
            Text('Bienvenido de nuevo',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center),
            Text('Conectando comerciantes con el mundo',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center),
          ]),

          // Email
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Correo electrónico'),
            const SizedBox(height: 4),
            _field(
              controller: _emailController,
              hint: 'tucorreo@ejemplo.com',
              icon: Icons.mail_outline_rounded,
              type: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'El correo es obligatorio';
                if (!_isValidEmail(v)) return 'Ingresa un correo válido';
                return null;
              },
            ),
          ]),

          // Password
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _label('Contraseña'),
              TextButton(
                onPressed: _isLoading ? null : _handlePasswordReset,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('¿Olvidaste tu contraseña?',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _orange)),
              ),
            ]),
            const SizedBox(height: 4),
            _field(
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'La contraseña es obligatoria';
                }
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
          ]),

          // Login button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (_isLoading || !_isConnected) ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: _orange.withValues(alpha: 0.35),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 2.5))
                  : Text('Ingresar al Marketplace',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),

          // Divider
          Row(children: [
            const Expanded(
                child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('O CONTINÚA CON',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w500)),
            ),
            const Expanded(
                child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
          ]),

          // Social buttons
          Row(children: [
            Expanded(
              child: _socialBtn(
                onTap:
                    (_isLoading || !_isConnected) ? null : _handleGoogleLogin,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _googleIcon(),
                  const SizedBox(width: 8),
                  Text('Google',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151))),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 50,
              height: 46,
              child: _socialBtn(
                onTap: (_isLoading || !_isConnected) ? null : _handleBiometric,
                child: const Icon(Icons.fingerprint,
                    size: 22, color: Color(0xFF374151)),
              ),
            ),
          ]),

          // Register link
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('¿Aún no vendes con nosotros? ',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFF64748B))),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: Text('Regístrate',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _green)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151)));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: type,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 19),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 19),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword))
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
          errorStyle: GoogleFonts.plusJakartaSans(fontSize: 10),
        ),
      );

  Widget _socialBtn({required Widget child, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Center(child: child),
        ),
      );

  Widget _googleIcon() => SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _GoogleGPainter()),
      );

  Widget _buildConnectivityBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.wifi_off_rounded, color: _orange, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Sin conexión a internet',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9A3412))),
          ),
        ]),
      );
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final scaleX = s.width / 24.0;
    final scaleY = s.height / 24.0;

    Path fromPoints(List<List<double>> cmds) {
      final path = Path();
      for (final cmd in cmds) {
        switch (cmd[0].toInt()) {
          case 0:
            path.moveTo(cmd[1] * scaleX, cmd[2] * scaleY);
            break;
          case 1:
            path.lineTo(cmd[1] * scaleX, cmd[2] * scaleY);
            break;
          case 2:
            path.cubicTo(
              cmd[1] * scaleX,
              cmd[2] * scaleY,
              cmd[3] * scaleX,
              cmd[4] * scaleY,
              cmd[5] * scaleX,
              cmd[6] * scaleY,
            );
            break;
          case 3:
            path.close();
            break;
        }
      }
      return path;
    }

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
        fromPoints([
          [0, 12, 5.04],
          [2, 13.64, 5.04, 15.12, 5.60, 16.28, 6.71],
          [1, 19.49, 3.50],
          [2, 17.51, 1.63, 14.97, 1.0, 12.0, 1.0],
          [2, 7.42, 1.0, 3.53, 3.63, 1.66, 7.45],
          [1, 5.43, 10.38],
          [2, 6.31, 7.26, 8.94, 5.04, 12.0, 5.04],
          [3],
        ]),
        paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
        fromPoints([
          [0, 23.49, 12.27],
          [2, 23.49, 11.45, 23.42, 10.66, 23.28, 9.89],
          [1, 12.0, 9.89],
          [1, 12.0, 14.39],
          [1, 18.44, 14.39],
          [2, 18.16, 15.87, 17.33, 17.13, 16.08, 17.98],
          [1, 19.74, 20.82],
          [2, 21.88, 18.85, 23.49, 15.94, 23.49, 12.27],
          [3],
        ]),
        paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
        fromPoints([
          [0, 5.43, 13.27],
          [2, 5.19, 12.56, 5.05, 11.80, 5.05, 11.0],
          [2, 5.05, 10.20, 5.19, 9.44, 5.43, 8.73],
          [1, 1.66, 5.80],
          [2, 0.60, 7.96, 0.0, 10.39, 0.0, 13.0],
          [2, 0.0, 15.61, 0.60, 18.04, 1.66, 20.20],
          [1, 5.43, 17.27],
          [3],
        ]),
        paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
        fromPoints([
          [0, 12.0, 23.0],
          [2, 15.24, 23.0, 17.96, 21.93, 19.95, 20.09],
          [1, 16.29, 17.25],
          [2, 15.19, 17.99, 13.78, 18.43, 12.0, 18.43],
          [2, 8.94, 18.43, 6.31, 16.21, 5.43, 13.09],
          [1, 1.66, 16.02],
          [2, 3.53, 19.84, 7.42, 23.0, 12.0, 23.0],
          [3],
        ]),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
