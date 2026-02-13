import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_service.dart';
import 'register_screen.dart';
import 'theme/app_theme.dart';

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

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
      if (mounted) {
        setState(() => _isConnected = connected);
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isConnected) {
      _showMessage(
        'Sin conexión a internet. Por favor verifica tu conexión.',
        isError: true,
      );
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
      _showMessage('¡Bienvenido!', isError: false);
    } else {
      _showMessage(error, isError: true);
    }
  }

  void _handleGoogleLogin() async {
    if (!_isConnected) {
      _showMessage(
        'Sin conexión a internet. Por favor verifica tu conexión.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.saveUser(user);
      }
      _showMessage('¡Bienvenido con Google!', isError: false);
    } else if (error != 'Inicio de sesión cancelado') {
      _showMessage(error, isError: true);
    }
  }

  void _handlePasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      _showMessage(
        'Por favor ingresa un correo válido en el campo de arriba',
        isError: true,
      );
      return;
    }

    if (!_isConnected) {
      _showMessage(
        'Sin conexión a internet. Por favor verifica tu conexión.',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Text(
          '¿Enviar instrucciones de recuperación a:\n\n$email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
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

      _showMessage(
        '✅ Revisa tu correo ($email) para restablecer tu contraseña',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      if (e.code == 'user-not-found') {
        _showMessage('No existe una cuenta con ese correo', isError: true);
      } else {
        _showMessage('Error al enviar correo. Por favor intenta de nuevo.',
            isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error inesperado. Por favor intenta de nuevo.',
          isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppTheme.textLight,
              size: 20,
            ),
            const SizedBox(width: AppTheme.paddingM),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium),
        margin: const EdgeInsets.all(AppTheme.paddingM),
        padding: const EdgeInsets.all(AppTheme.paddingM),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _connectivityService.isConnected,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _isConnected = snapshot.data ?? true;
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: Stack(
            children: [
              // Fondo decorativo con gradiente
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF5F5F5),
                      Color(0xFFFFFFFF),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Indicador de conectividad
                              if (!_isConnected) _buildConnectivityBanner(),
                              const SizedBox(height: AppTheme.paddingL),

                              // Logo animado profesional
                              _buildLogoSection(),
                              const SizedBox(height: AppTheme.paddingXL),

                              // Tarjeta de login
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppTheme.radiusLarge,
                                  boxShadow: const [AppTheme.shadowMedium],
                                ),
                                padding: const EdgeInsets.all(AppTheme.paddingL),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Título
                                    Text(
                                      'Inicia Sesión',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.paddingS),

                                    // Subtítulo
                                    Text(
                                      'Accede a la plataforma de Urabá',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.paddingL),

                                    // Email field
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Correo electrónico',
                                      icon: Icons.email_outlined,
                                      type: TextInputType.emailAddress,
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'El correo es obligatorio';
                                        }
                                        if (!_isValidEmail(val)) {
                                          return 'Ingresa un correo válido (ej: usuario@ejemplo.com)';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.paddingM),

                                    // Password field
                                    _buildTextField(
                                      controller: _passwordController,
                                      label: 'Contraseña',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'La contraseña es obligatoria';
                                        }
                                        if (val.length < 6) {
                                          return 'La contraseña debe tener al menos 6 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.paddingS),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handlePasswordReset,
                                        child: const Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.paddingM),

                                    // Login button
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: (_isLoading || !_isConnected)
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryGreen,
                                          foregroundColor:
                                              AppTheme.textLight,
                                          disabledBackgroundColor:
                                              Colors.grey.shade300,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                AppTheme.radiusMedium,
                                          ),
                                          elevation: 2,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    AppTheme.textLight,
                                                  ),
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'INGRESAR',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppTheme.paddingL),

                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      color: AppTheme.borderGrey,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.paddingM,
                                    ),
                                    child: Text(
                                      'O continúa con',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textGrey,
                                          ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: AppTheme.borderGrey,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.paddingL),

                              // Google button
                              SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: (_isLoading || !_isConnected)
                                      ? null
                                      : _handleGoogleLogin,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppTheme.borderGrey,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          AppTheme.radiusMedium,
                                    ),
                                  ),
                                  icon: Image.network(
                                    'https://www.google.com/favicon.ico',
                                    height: 24,
                                  ),
                                  label: const Text(
                                    'Entrar con Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppTheme.paddingXL),

                              // Link a registro
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿Aún no vendes con nosotros? ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Regístrate',
                                      style: TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [AppTheme.shadowMedium],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.paddingL),
        Text(
          'Urabá Digital',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.paddingS),
        Text(
          'Mercado justo para nuestra región',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
                fontSize: 15,
              ),
        ),
      ],
    );
  }

  Widget _buildConnectivityBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: AppTheme.accentOrange, width: 1),
        boxShadow: const [AppTheme.shadowSmall],
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: AppTheme.accentOrange, size: 20),
          SizedBox(width: AppTheme.paddingM),
          Expanded(
            child: Text(
              'Sin conexión a internet',
              style: TextStyle(
                color: AppTheme.accentOrangeDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.primaryGreen,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        border: OutlineInputBorder(borderRadius: AppTheme.radiusMedium),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingM,
          vertical: AppTheme.paddingM,
        ),
        errorMaxLines: 2,
      ),
    );
  }
}
