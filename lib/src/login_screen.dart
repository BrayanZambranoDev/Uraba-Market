import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_service.dart';
import 'register_screen.dart';
import 'auth_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'utils/validators.dart';
import 'package:iconsax/iconsax.dart';

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

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isConnected = true;
  bool _showSuccessAnimation = false;

  static const _bg = Color(0xFF0A0F0A);
  static const _card = Color(0xFF131C13);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: const Interval(0.0, 0.6));
    _animCtrl.forward();
    _connectivityService.checkConnectivity().then((c) {
      if (mounted) setState(() => _isConnected = c);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isConnected) { _showMsg('Sin conexión a internet.', isError: true); return; }
    setState(() => _isLoading = true);
    final error = await _authService.login(
        _emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      await _onAuthSuccess(FirebaseAuth.instance.currentUser, fromGoogle: false);
    } else {
      _showMsg(error, isError: true);
    }
  }

  void _handleGoogleLogin() async {
    if (!_isConnected) { _showMsg('Sin conexión a internet.', isError: true); return; }
    setState(() => _isLoading = true);
    final error = await _authService.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      await _onAuthSuccess(FirebaseAuth.instance.currentUser, fromGoogle: true);
    } else if (error != 'Inicio de sesión cancelado') {
      _showMsg(error, isError: true);
    }
  }

  void _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !Validators.isValidEmail(email)) {
      _showMsg('Ingresa un correo válido para recuperar la contraseña', isError: true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        title: Text('Recuperar contraseña',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text('¿Enviar instrucciones a:\n\n$email?',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull)),
            child: Text('Enviar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white)),
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
      _showMsg('Revisa tu correo ($email)', isError: false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMsg('Error al enviar correo. Intenta de nuevo.', isError: true);
    }
  }

  Future<void> _onAuthSuccess(User? user, {bool fromGoogle = false}) async {
    if (user != null) await _firestoreService.saveUser(user);
    if (!mounted) return;
    setState(() => _showSuccessAnimation = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    if (user != null && !user.emailVerified && !fromGoogle) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Iconsax.sms, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Verifica tu email para mayor seguridad',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12))),
        ]),
        action: SnackBarAction(
          label: 'Reenviar', textColor: Colors.white,
          onPressed: () async => await _authService.resendVerificationEmail(),
        ),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM),
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  void _showMsg(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Iconsax.warning_2 : Iconsax.tick_circle,
            color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: isError ? AppTheme.error : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final heroH = MediaQuery.of(context).size.height * 0.38;
    return StreamBuilder<bool>(
      stream: _connectivityService.isConnected,
      builder: (context, snapshot) {
        if (snapshot.hasData) _isConnected = snapshot.data ?? true;
        return Scaffold(
          backgroundColor: _bg,
          body: Stack(children: [
            Column(children: [
              // Hero imagen
              SizedBox(
                height: heroH,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(_kBackgroundUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A2E1A))),
                  DecoratedBox(decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        _bg.withValues(alpha: 0.35),
                        _bg.withValues(alpha: 0.75),
                        _bg,
                      ],
                      stops: const [0.0, 0.20, 0.50, 0.75, 1.0],
                    ),
                  )),
                  // Badge
                  SafeArea(child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: AppTheme.radiusFull,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 22, height: 22,
                              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                              child: const Icon(Iconsax.tree, color: Colors.white, size: 13)),
                          const SizedBox(width: 8),
                          Text('Urabá Market', style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                        ]),
                      ),
                    ),
                  )),
                ]),
              ),
              // Panel
              Expanded(child: ColoredBox(
                color: _bg,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      24, 52, 24, 24 + MediaQuery.of(context).padding.bottom),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Form(
                        key: _formKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          RichText(textAlign: TextAlign.center, text: TextSpan(children: [
                            TextSpan(text: '¡Bienvenido de ',
                                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                            TextSpan(text: 'nuevo!',
                                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                          ])),
                          const SizedBox(height: 4),
                          Text('Conectamos a comerciantes con el mundo',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          if (!_isConnected) ...[_buildConnBanner(), const SizedBox(height: 14)],
                          _label('Correo electrónico'),
                          const SizedBox(height: 6),
                          _field(controller: _emailController, hint: 'tuemail@ejemplo.com',
                              icon: Iconsax.sms, type: TextInputType.emailAddress, validator: Validators.email),
                          const SizedBox(height: 14),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            _label('Contraseña'),
                            GestureDetector(
                              onTap: _isLoading ? null : _handlePasswordReset,
                              child: Text('¿Olvidaste tu contraseña?', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          _field(controller: _passwordController, hint: '••••••••',
                              icon: Iconsax.lock, isPassword: true, validator: Validators.password),
                          const SizedBox(height: 22),
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: AppTheme.radiusFull,
                              boxShadow: (_isLoading || !_isConnected)
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.45),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_isConnected) ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2.5))
                                  : Text('Ingresar al Marketplace',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(children: [
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('O CONTINÚA CON', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                                    color: Colors.white.withValues(alpha: 0.35)))),
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
                          ]),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: (_isLoading || !_isConnected) ? null : _handleGoogleLogin,
                            borderRadius: AppTheme.radiusFull,
                            child: Container(height: 52,
                              decoration: BoxDecoration(
                                color: _card, borderRadius: AppTheme.radiusFull,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                _googleIcon(),
                                const SizedBox(width: 10),
                                Text('Continuar con Google', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('¿Aún no vendes con nosotros?  ', style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                            GestureDetector(
                              onTap: () => Navigator.push(context, AppTheme.pageRoute(const RegisterScreen())),
                              child: Text('Regístrate', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                            ),
                          ]),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),
                  ),
                ),
              )),
            ]),
            // Icono en la unión
            Positioned(top: heroH - 36, left: 0, right: 0,
              child: Center(child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _bg,
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2.5)),
                child: Center(child: Container(width: 52, height: 52,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Iconsax.tree, color: Colors.white, size: 28))),
              )),
            ),
            if (_showSuccessAnimation)
              Positioned.fill(child: Container(color: Colors.black54,
                child: Center(child: Container(width: 100, height: 100,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Iconsax.check, color: Colors.white, size: 56))),
              )),
          ]),
        );
      },
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white));

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
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.30)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.40), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
                      color: Colors.white.withValues(alpha: 0.40), size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
              : null,
          filled: true,
          fillColor: _card,
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
          enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
          focusedBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: AppTheme.primary, width: 2.2)),
          errorBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: AppTheme.error, width: 2)),
          errorStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.error),
        ),
      );

  Widget _googleIcon() => SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleGPainter()));

  Widget _buildConnBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1),
        borderRadius: AppTheme.radiusM,
        border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
    child: Row(children: [
      Icon(Icons.wifi_off_rounded, color: Colors.red.withValues(alpha: 0.8), size: 17),
      const SizedBox(width: 10),
      Expanded(child: Text('Sin conexión a internet',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8)))),
    ]),
  );
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final sx = s.width / 24.0;
    final sy = s.height / 24.0;
    Path fp(List<List<double>> c) {
      final p = Path();
      for (final d in c) {
        switch (d[0].toInt()) {
          case 0: p.moveTo(d[1]*sx, d[2]*sy); break;
          case 1: p.lineTo(d[1]*sx, d[2]*sy); break;
          case 2: p.cubicTo(d[1]*sx,d[2]*sy,d[3]*sx,d[4]*sy,d[5]*sx,d[6]*sy); break;
          case 3: p.close(); break;
        }
      }
      return p;
    }
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(fp([[0,12,5.04],[2,13.64,5.04,15.12,5.60,16.28,6.71],[1,19.49,3.50],[2,17.51,1.63,14.97,1.0,12.0,1.0],[2,7.42,1.0,3.53,3.63,1.66,7.45],[1,5.43,10.38],[2,6.31,7.26,8.94,5.04,12.0,5.04],[3]]), paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(fp([[0,23.49,12.27],[2,23.49,11.45,23.42,10.66,23.28,9.89],[1,12.0,9.89],[1,12.0,14.39],[1,18.44,14.39],[2,18.16,15.87,17.33,17.13,16.08,17.98],[1,19.74,20.82],[2,21.88,18.85,23.49,15.94,23.49,12.27],[3]]), paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(fp([[0,5.43,13.27],[2,5.19,12.56,5.05,11.80,5.05,11.0],[2,5.05,10.20,5.19,9.44,5.43,8.73],[1,1.66,5.80],[2,0.60,7.96,0.0,10.39,0.0,13.0],[2,0.0,15.61,0.60,18.04,1.66,20.20],[1,5.43,17.27],[3]]), paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(fp([[0,12.0,23.0],[2,15.24,23.0,17.96,21.93,19.95,20.09],[1,16.29,17.25],[2,15.19,17.99,13.78,18.43,12.0,18.43],[2,8.94,18.43,6.31,16.21,5.43,13.09],[1,1.66,16.02],[2,3.53,19.84,7.42,23.0,12.0,23.0],[3]]), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
