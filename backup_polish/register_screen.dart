import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/connectivity_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'complete_profile_screen.dart';
import 'theme/app_theme.dart';
import 'utils/validators.dart';
import 'package:iconsax/iconsax.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _connectivityService = ConnectivityService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  static const _bg = Color(0xFF0A0F0A);
  static const _card = Color(0xFF131C13);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleGoogleLogin() async {
    final connected = await _connectivityService.checkConnectivity();
    if (!connected) { _showMsg('Sin conexión a internet.', isError: true); return; }
    setState(() => _isLoading = true);
    final error = await _authService.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) await _firestoreService.saveUser(user);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          AppTheme.pageRoute(const CompleteProfileScreen()), (route) => false);
    } else if (error != 'Inicio de sesión cancelado') {
      _showMsg(error, isError: true);
    }
  }

  void _handleRegister() async {
    if (!_acceptTerms) { _showMsg('Debes aceptar los términos y condiciones', isError: true); return; }
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMsg('Las contraseñas no coinciden', isError: true);
      return;
    }
    final connected = await _connectivityService.checkConnectivity();
    if (!connected) { _showMsg('Sin conexión a internet.', isError: true); return; }
    setState(() => _isLoading = true);
    final error = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      displayName: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      Navigator.pushAndRemoveUntil(context,
          AppTheme.pageRoute(const CompleteProfileScreen()), (route) => false);
    } else {
      _showMsg(error, isError: true);
    }
  }

  void _showMsg(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Iconsax.close_circle : Iconsax.tick_circle, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.plusJakartaSans(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final heroH = MediaQuery.of(context).size.height * 0.36;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        Column(children: [
          // Hero imagen
          SizedBox(
            height: heroH,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/register_bg.jpg', fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(gradient: AppTheme.heroHeaderGradient))),
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
              // Botón atrás
              SafeArea(child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              )),
            ]),
          ),
          // Formulario
          Expanded(child: ColoredBox(color: _bg, child: const SizedBox.expand())),
        ]),

        // Ícono en la unión (igual que login)
        Positioned(top: heroH - 36, left: 0, right: 0,
          child: Center(child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _bg,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2.5)),
            child: Center(child: Container(width: 52, height: 52,
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: const Icon(Iconsax.user_add, color: Colors.white, size: 26))),
          )),
        ),

        // Formulario scroll encima
        Positioned.fill(
          top: heroH + 10,
          child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Crear Cuenta', style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  RichText(textAlign: TextAlign.center, text: TextSpan(children: [
                    TextSpan(text: 'Únete a la ', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                    TextSpan(text: 'comunidad', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    TextSpan(text: ' de Urabá.', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                  ])),
                  const SizedBox(height: 24),

                  _label('Nombre completo'),
                  const SizedBox(height: 4),
                  _field(controller: _nameController, hint: 'Tu nombre completo',
                      icon: Iconsax.user, validator: Validators.nombre),
                  const SizedBox(height: 14),

                  _label('Correo electrónico'),
                  const SizedBox(height: 4),
                  _field(controller: _emailController, hint: 'tucorreo@ejemplo.com',
                      icon: Iconsax.sms, type: TextInputType.emailAddress,
                      validator: Validators.email),
                  const SizedBox(height: 14),

                  _label('Contraseña'),
                  const SizedBox(height: 4),
                  _field(controller: _passwordController, hint: '••••••••',
                      icon: Iconsax.lock, isPassword: true,
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: Validators.password),
                  const SizedBox(height: 14),

                  _label('Confirmar contraseña'),
                  const SizedBox(height: 4),
                  _field(controller: _confirmPasswordController, hint: '••••••••',
                      icon: Iconsax.lock, isPassword: true,
                      obscure: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      validator: (v) => Validators.confirmPassword(v, _passwordController.text)),
                  const SizedBox(height: 16),

                  // Términos
                  GestureDetector(
                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _acceptTerms ? AppTheme.primary.withValues(alpha: 0.08) : _card,
                        borderRadius: AppTheme.radiusM,
                        border: Border.all(
                          color: _acceptTerms ? AppTheme.primary : Colors.white.withValues(alpha: 0.10),
                          width: 1.5,
                        ),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: _acceptTerms ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _acceptTerms ? AppTheme.primary : Colors.white.withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: _acceptTerms
                              ? const Icon(Iconsax.check, color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Acepto los términos y condiciones',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          Text('Cumplimiento Ley 527/1999 y Ley 1581/2012',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
                        ])),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón crear cuenta
                  SizedBox(height: 52, child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                        : Text('CREAR CUENTA', style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  )),
                  const SizedBox(height: 16),

                  // Divisor
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o', style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.35)))),
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
                  ]),
                  const SizedBox(height: 16),

                  // Google
                  InkWell(
                    onTap: _isLoading ? null : _handleGoogleLogin,
                    borderRadius: AppTheme.radiusM,
                    child: Container(height: 50,
                      decoration: BoxDecoration(
                        color: _card, borderRadius: AppTheme.radiusM,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1.5),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _googleIcon(),
                        const SizedBox(width: 8),
                        Text('Registrarse con Google', style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('¿Ya tienes cuenta? ', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Inicia sesión', style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: isPassword && obscure,
        keyboardType: type,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.30)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.40), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(obscure ? Iconsax.eye : Iconsax.eye_slash,
                      color: Colors.white.withValues(alpha: 0.40), size: 20),
                  onPressed: onToggle)
              : null,
          filled: true,
          fillColor: _card,
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
          enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
          focusedBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.8)),
          errorBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: AppTheme.error, width: 2)),
          errorStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.error),
        ),
      );

  Widget _googleIcon() => SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleLogoPainter()));
}

class _GoogleLogoPainter extends CustomPainter {
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
