import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'auth_wrapper.dart';
import 'edit_profile_screen.dart';
import 'package:iconsax/iconsax.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', val);
    if (mounted) setState(() => _notificationsEnabled = val);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        title: Text('Cerrar sesión',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text('¿Estás seguro de que quieres salir?',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusFull),
              elevation: 0,
            ),
            child: Text('Salir',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: AppTheme.radiusS,
            ),
            child: const Icon(Iconsax.shop,
                color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Urabá Market',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutRow('Versión', '1.0.0'),
            const SizedBox(height: 8),
            _aboutRow('Plataforma', 'Flutter + Firebase'),
            const SizedBox(height: 8),
            _aboutRow('Región', 'Urabá, Antioquia, Colombia'),
            const SizedBox(height: 16),
            Text(
              'Marketplace local que conecta compradores y productores de la región de Urabá.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusFull),
              elevation: 0,
            ),
            child: Text('Cerrar',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Política de Privacidad',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                '''Urabá Market recopila información personal como nombre, correo electrónico y datos de perfil para facilitar las transacciones entre compradores y vendedores en la región de Urabá.

Cumplimiento legal:
• Ley 1581 de 2012 (Protección de Datos Personales)
• Ley 527 de 1999 (Comercio Electrónico)
• Decreto 1377 de 2013

Uso de datos:
Los datos personales se utilizan exclusivamente para la operación de la plataforma y nunca son compartidos con terceros sin consentimiento explícito.

Derechos del titular:
Puedes solicitar la consulta, rectificación, actualización o supresión de tus datos contactándonos directamente.

Almacenamiento:
Los datos se almacenan en Firebase (Google Cloud) con cifrado en reposo y en tránsito.

Cookies y preferencias:
La app almacena preferencias locales (historial de búsqueda, configuración) únicamente en tu dispositivo.

Para ejercer tus derechos o reportar un problema, contáctanos desde la sección de Ayuda de la app.''',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.7),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showTerms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Términos y Condiciones',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                '''Al usar Urabá Market aceptas los siguientes términos:

1. USO DE LA PLATAFORMA
Urabá Market es una plataforma de intermediación entre compradores y vendedores locales. No somos responsables de la calidad, entrega o veracidad de los productos publicados.

2. REGISTRO
Debes proporcionar información verídica al registrarte. El uso de cuentas falsas está prohibido.

3. PUBLICACIÓN DE PRODUCTOS
Los vendedores son responsables de la veracidad de sus publicaciones, precios y disponibilidad de stock.

4. TRANSACCIONES
Las transacciones se realizan directamente entre compradores y vendedores. Urabá Market facilita la comunicación pero no interviene en el pago ni la entrega.

5. CALIFICACIONES
Las reseñas deben ser honestas y basadas en experiencias reales. Las reseñas falsas o malintencionadas serán eliminadas.

6. CONDUCTA
Está prohibido el uso de lenguaje ofensivo, fraude, spam o cualquier conducta que perjudique a otros usuarios.

7. PRIVACIDAD
El tratamiento de datos se rige por nuestra Política de Privacidad y la Ley 1581 de 2012.

8. MODIFICACIONES
Nos reservamos el derecho de modificar estos términos con previo aviso de 30 días.''',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.7),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _aboutRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );

  static const _bg = Color(0xFF0A0F0A);
  static const _card = Color(0xFF131C13);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        // Header
        Container(
          color: _bg,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ajustes', style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Administra tu cuenta, preferencias y más',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
                  ]),
                ),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.setting_2, color: AppTheme.primary, size: 20),
                ),
              ]),
            ),
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Cuenta'),
              _settingsCard([
                _tile(icon: Iconsax.user, iconColor: AppTheme.primary,
                    title: 'Editar perfil', subtitle: 'Nombre, foto y rol',
                    onTap: () => Navigator.push(context, AppTheme.pageRoute(const EditProfileScreen()))),
                _divider(),
                _tile(icon: Iconsax.lock, iconColor: const Color(0xFF6366F1),
                    title: 'Cambiar contraseña', subtitle: 'Enviar enlace de recuperación',
                    onTap: _sendPasswordReset),
              ]),
              const SizedBox(height: 16),

              _sectionTitle('Preferencias'),
              _settingsCard([
                _toggleTile(icon: Iconsax.notification, iconColor: const Color(0xFFF59E0B),
                    title: 'Notificaciones', subtitle: 'Alertas de pedidos y mensajes',
                    value: _notificationsEnabled, onChanged: _toggleNotifications),
              ]),
              const SizedBox(height: 16),

              _sectionTitle('Legal'),
              _settingsCard([
                _tile(icon: Iconsax.document_text, iconColor: const Color(0xFF06B6D4),
                    title: 'Términos y condiciones', onTap: _showTerms),
                _divider(),
                _tile(icon: Iconsax.shield_tick, iconColor: AppTheme.primary,
                    title: 'Política de privacidad', subtitle: 'Ley 1581/2012',
                    onTap: _showPrivacyPolicy),
                _divider(),
                _tile(icon: Iconsax.info_circle, iconColor: Colors.white.withValues(alpha: 0.4),
                    title: 'Acerca de la app', subtitle: 'Versión 1.0.0',
                    onTap: _showAbout),
              ]),
              const SizedBox(height: 16),

              // Cerrar sesión
              GestureDetector(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A0A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Iconsax.logout, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Text('Cerrar sesión', style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // Footer
              Center(
                child: Column(children: [
                  Image.asset('imagen conversaciones.png', width: 40, height: 40),
                  const SizedBox(height: 6),
                  Text('Urabá Market v1.0.0', style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  Text('Gracias por usar nuestra app ❤️', style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
                ]),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _sendPasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Correo enviado a $email',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al enviar el correo',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w800,
            color: AppTheme.primary, letterSpacing: 1.2)),
      );

  Widget _settingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(children: children),
      );

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: titleColor ?? Colors.white)),
              if (subtitle != null) Text(subtitle, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
            ])),
            if (onTap != null)
              Icon(Iconsax.arrow_right, color: Colors.white.withValues(alpha: 0.3), size: 20),
          ]),
        ),
      );

  Widget _toggleTile({
    required IconData icon, required Color iconColor,
    required String title, String? subtitle,
    required bool value, required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            if (subtitle != null) Text(subtitle, style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
          ])),
          Switch.adaptive(value: value, onChanged: onChanged,
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withValues(alpha: 0.4)),
        ]),
      );

  Widget _divider() => Divider(height: 1, indent: 68, endIndent: 16,
        color: Colors.white.withValues(alpha: 0.06));
}
