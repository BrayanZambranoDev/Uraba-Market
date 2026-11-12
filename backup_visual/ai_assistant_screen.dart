import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'theme/app_theme.dart';
import 'services/gemini_service.dart';
import 'package:iconsax/iconsax.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatMessage {
  String text;
  final bool isUser;
  final DateTime time;
  bool isLoading;
  bool isError;
  final Uint8List? imageBytes;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
    this.isLoading = false,
    this.imageBytes,
  }) : isError = false, time = time ?? DateTime.now();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with TickerProviderStateMixin {
  final GeminiService _gemini = GeminiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isInitializing = true;
  bool _isSending = false;
  bool _showScrollDown = false;
  bool _restoredFromHistory = false;
  String _userName = '';
  String? _sessionId;

  late AnimationController _welcomeAnim;
  late Animation<double> _welcomeFade;
  late AnimationController _pulseAnim;
  late Animation<double> _pulseValue;
  late AnimationController _dotsAnim;

  static const List<Map<String, dynamic>> _popularQuestions = [
    {'icon': Iconsax.bag,   'color': Color(0xFF16A34A), 'q': '¿Cuáles son los productos más vendidos en Urabá?'},
    {'icon': Iconsax.tree,            'color': Color(0xFF16A34A), 'q': '¿Qué productos están en temporada ahora?'},
    {'icon': Iconsax.truck, 'color': Color(0xFF0891B2), 'q': '¿Cómo funcionan los envíos en Urabá?'},
    {'icon': Iconsax.shop,     'color': Color(0xFF0E7C86), 'q': '¿Cómo puedo empezar a vender en Urabá Market?'},
  ];

  final Map<String, List<String>> _followUpMap = {
    'precio': ['¿Y para otra categoría?', '¿Cómo fijar ofertas?', '¿Margen ideal?'],
    'descripci': ['Hazla más corta', 'Versión más formal', 'Con emojis'],
    'tendencia': ['¿Qué se vende más aquí?', '¿Qué debería publicar?', '¿Hay temporada?'],
    'estrategia': ['¿Cómo atraer clientes?', '¿Debería hacer ofertas?', '¿Mejorar perfil?'],
    'producto': ['¿Hay más opciones?', '¿Quién lo vende?', '¿Precio justo?'],
    'vendedor': ['¿Tiene más productos?', '¿Cómo contactarlo?', '¿Es confiable?'],
  };

  @override
  void initState() {
    super.initState();
    _welcomeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _welcomeFade = CurvedAnimation(parent: _welcomeAnim, curve: Curves.easeIn);

    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseValue = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));

    _dotsAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

    _scrollController.addListener(() {
      final show = _scrollController.hasClients &&
          _scrollController.offset < _scrollController.position.maxScrollExtent - 100;
      if (show != _showScrollDown) setState(() => _showScrollDown = show);
    });

    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      _userName = user?.displayName?.split(' ').first ?? '';
      await _gemini.startChat(user?.uid ?? '');
    } catch (_) {}
    if (mounted) {
      setState(() => _isInitializing = false);
      _welcomeAnim.forward();
    }
  }

  @override
  void dispose() {
    _saveConversation();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _welcomeAnim.dispose();
    _pulseAnim.dispose();
    _dotsAnim.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool fast = false}) {
    Future.delayed(Duration(milliseconds: fast ? 50 : 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: fast ? 100 : 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _getSuggestions(String response) {
    final lower = response.toLowerCase();
    for (final entry in _followUpMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return ['Cuéntame más', '¿Qué más recomiendas?', 'Otra pregunta'];
  }

  // ═══════════════════════════════════════════════════════════
  // ENVIAR MENSAJE CON STREAMING
  // ═══════════════════════════════════════════════════════════

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    HapticFeedback.lightImpact();
    _controller.clear();
    _focusNode.unfocus();
    _restoredFromHistory = false;
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      // Mensaje de IA vacío que se irá llenando con streaming
      _messages.add(_ChatMessage(text: '', isUser: false, isLoading: true));
      _isSending = true;
    });
    _scrollToBottom();

    final aiMsgIndex = _messages.length - 1;

    final response = await _gemini.sendMessageStream(
      text.trim(),
      onToken: (token) {
        if (!mounted) return;
        setState(() {
          _messages[aiMsgIndex].text += token;
          _messages[aiMsgIndex].isLoading = false;
        });
        _scrollToBottom(fast: true);
      },
    );

    if (mounted) {
      final isError = response.startsWith('Los servidores') || response.startsWith('Error');
      setState(() {
        // Asegurar que el texto final esté completo
        _messages[aiMsgIndex].text = response;
        _messages[aiMsgIndex].isLoading = false;
        _messages[aiMsgIndex].isError = isError;
        _isSending = false;
      });

      // Agregar sugerencias como mensaje separado invisible
      if (!isError && _messages.length > 1) {
        // Las sugerencias se muestran inline en el último mensaje
      }
      _scrollToBottom();
      if (!isError) _saveConversation();
    }
  }

  Future<void> _analyzeImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, maxHeight: 1024, imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatMessage(
        text: 'Analiza esta imagen',
        isUser: true,
        imageBytes: Uint8List.fromList(bytes),
      ));
      _messages.add(_ChatMessage(text: '', isUser: false, isLoading: true));
      _isSending = true;
    });
    _scrollToBottom();

    final response = await _gemini.analyzeProductImage(Uint8List.fromList(bytes));

    if (mounted) {
      // Inyectar el análisis de imagen al historial del chat de texto
      // para que Groq tenga contexto cuando pregunten sobre la foto
      _gemini.injectImageContext(response);

      setState(() {
        _messages.removeLast();
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _retryLastMessage() {
    if (_messages.length < 2) return;
    // Encontrar el último mensaje del usuario
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        final text = _messages[i].text;
        // Remover mensajes desde el usuario en adelante
        setState(() => _messages.removeRange(i, _messages.length));
        _sendMessage(text);
        break;
      }
    }
  }

  void _showMessageActions(String text) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            _actionTile(Iconsax.copy, 'Copiar texto', () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              _showSnack('Texto copiado', AppTheme.green);
            }),
            _actionTile(Iconsax.share, 'Compartir', () {
              Navigator.pop(ctx);
              Share.share(text);
            }),
            _actionTile(Iconsax.refresh, 'Regenerar', () {
              Navigator.pop(ctx);
              _retryLastMessage();
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HISTORIAL — guardar y mostrar
  // ═══════════════════════════════════════════════════════════

  Future<void> _saveConversation() async {
    if (_restoredFromHistory) return;
    final validMsgs = _messages.where((m) => !m.isLoading && m.text.isNotEmpty).toList();
    if (validMsgs.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firstUser = validMsgs.firstWhere((m) => m.isUser, orElse: () => validMsgs.first);
    final title = firstUser.text.length > 60 ? '${firstUser.text.substring(0, 57)}...' : firstUser.text;

    try {
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_historial');

      _sessionId ??= col.doc().id;

      await col.doc(_sessionId).set({
        'title': title,
        'mensajes': validMsgs.map((m) => {
          'texto': m.text,
          'esUsuario': m.isUser,
          'hora': m.time.toIso8601String(),
        }).toList(),
        'creadoEn': FieldValue.serverTimestamp(),
        'totalMensajes': validMsgs.length,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando conversación IA: $e');
    }
  }

  void _showHistorial() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        margin: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Historial de conversaciones',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Iconsax.close_circle, color: AppTheme.textMuted, size: 22),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Toca una conversación para continuarla',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.borderLight, height: 1),
          // Lista
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('ai_historial')
                  .orderBy('creadoEn', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Iconsax.clock, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('Aún no tienes conversaciones guardadas',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textMuted)),
                      const SizedBox(height: 6),
                      Text('Las conversaciones se guardan automáticamente',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                    ]),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Divider(color: AppTheme.borderLight, height: 1, indent: 70),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final title = data['title'] as String? ?? 'Conversación';
                    final total = data['totalMensajes'] as int? ?? 0;
                    final ts = data['creadoEn'] as Timestamp?;
                    final fecha = ts != null ? _formatFecha(ts.toDate()) : '';
                    final mensajes = (data['mensajes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.cpu, color: AppTheme.primary, size: 22),
                      ),
                      title: Text(title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(children: [
                          Icon(Iconsax.clock, size: 11, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(fecha, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted)),
                          const SizedBox(width: 10),
                          Icon(Iconsax.message, size: 11, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text('$total mensajes', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted)),
                        ]),
                      ),
                      trailing: GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dctx) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text('Eliminar conversación',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                              content: Text('¿Seguro que quieres eliminar esta conversación?',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dctx, false),
                                    child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted))),
                                TextButton(onPressed: () => Navigator.pop(dctx, true),
                                    child: Text('Eliminar', style: GoogleFonts.plusJakartaSans(color: AppTheme.error, fontWeight: FontWeight.w700))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await docs[i].reference.delete();
                          }
                        },
                        child: const Icon(Iconsax.trash, color: AppTheme.textMuted, size: 20),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _restoreConversacion(mensajes);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _restoreConversacion(List<Map<String, dynamic>> mensajes) {
    _gemini.resetChat();
    setState(() {
      _restoredFromHistory = true;
      _messages.clear();
      for (final m in mensajes) {
        _messages.add(_ChatMessage(
          text: m['texto'] as String? ?? '',
          isUser: m['esUsuario'] as bool? ?? false,
          time: DateTime.tryParse(m['hora'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    });
    _scrollToBottom();
    _showSnack('Conversación restaurada ✓', AppTheme.green);
  }

  String _formatFecha(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Hoy ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      onTap: onTap,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Stack(
              children: [
                _isInitializing
                    ? _buildInitializing()
                    : _messages.isEmpty
                        ? _buildWelcome()
                        : _buildChatList(),
                // Scroll-to-bottom FAB
                if (_showScrollDown && _messages.isNotEmpty)
                  Positioned(
                    bottom: 8, right: 16,
                    child: GestureDetector(
                      onTap: () => _scrollToBottom(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                        ),
                        child: const Icon(Iconsax.arrow_down, color: AppTheme.primary, size: 22),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!_isInitializing) _buildInputBar(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16, right: 16, bottom: 12,
      ),
      color: AppTheme.bg,
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle),
            child: const Icon(Iconsax.arrow_left, color: AppTheme.textPrimary, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        // Bot avatar
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: ClipOval(child: Image.asset('assets/images/ura_saludando.png', fit: BoxFit.cover)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Ura IA',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('BETA', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              ),
            ]),
            Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: _isSending ? const Color(0xFFFBBF24) : const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(_isSending ? 'Escribiendo...' : 'En línea',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted)),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: _showHistorial,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Iconsax.clock, color: AppTheme.textPrimary, size: 16),
              const SizedBox(width: 6),
              Text('Historial',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LOADING
  // ═══════════════════════════════════════════════════════════

  Widget _buildInitializing() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseValue,
            builder: (context, _) => Transform.scale(
              scale: 0.9 + (_pulseValue.value * 0.1),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1C3320), Color(0xFF0F1E12)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF1C3320).withValues(alpha: 0.3),
                    blurRadius: 30, offset: const Offset(0, 10),
                  )],
                ),
                child: const Icon(Iconsax.cpu, color: AppTheme.primary, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Preparando tu asistente...',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Cargando datos del marketplace',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 28),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                color: AppTheme.primary, backgroundColor: AppTheme.inputBg, minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WELCOME
  // ═══════════════════════════════════════════════════════════

  Widget _buildWelcome() {
    return FadeTransition(
      opacity: _welcomeFade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '¡Hola, ', style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    TextSpan(text: _userName.isNotEmpty ? '$_userName! 👋' : 'bienvenido! 👋',
                        style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ])),
                  const SizedBox(height: 8),
                  Text('Soy Ura, tu asistente inteligente. Estoy aquí para ayudarte a comprar, vender y descubrir lo mejor de Urabá.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                ]),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _pulseValue,
                builder: (ctx, _) => Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surface,
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.15 + _pulseValue.value * 0.1), blurRadius: 24, spreadRadius: 4)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('ura ia.png', fit: BoxFit.contain),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            // ── Título "¿En qué puedo ayudarte hoy?" ──
            Text('¿En qué puedo ayudarte hoy?',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            // ── 4 pills rápidas ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _pill('🔍 Buscar productos', '¿Qué productos están disponibles en Urabá ahora mismo?'),
                _pill('🌿 Precios de productos', '¿Cuáles son los productos con mejores precios en el marketplace?'),
                _pill('💰 Mejores ofertas', '¿Qué ofertas y descuentos hay disponibles hoy?'),
                _pill('🏪 Vender más fácil', '¿Cómo puedo vender más fácil y rápido en Urabá Market?'),
              ]),
            ),
            const SizedBox(height: 24),
            // ── Preguntarme lo que necesites ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Iconsax.cpu, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pregúntame lo que necesites',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Ej: "¿Dónde puedo conseguir plátano criollo en Turbo?"',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, height: 1.4)),
                  ]),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    await _saveConversation();
                    _gemini.resetChat();
                    setState(() { _messages.clear(); _sessionId = null; });
                    await _initChat();
                    _focusNode.requestFocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Nueva conversación',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            // ── Preguntas populares ──
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Preguntas populares', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text('Ver todas >', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ]),
            const SizedBox(height: 10),
            ..._popularQuestions.map((item) => GestureDetector(
              onTap: () => _sendMessage(item['q'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item['q'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary))),
                  const Icon(Iconsax.arrow_right, size: 14, color: AppTheme.textMuted),
                ]),
              ),
            )),
            const SizedBox(height: 24),
            // ── Recomendado para ti ──
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Recomendado para ti', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text('Ver más >', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('productos')
                    .where('activo', isEqualTo: true).limit(6).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final nombre = d['nombre'] as String? ?? '';
                      final precio = (d['precio'] as num?)?.toInt() ?? 0;
                      final imgUrl = d['imagenUrl'] as String?;
                      final municipio = d['municipio'] as String? ?? 'Urabá';
                      return GestureDetector(
                        onTap: () => _sendMessage('¿Cuéntame más sobre $nombre?'),
                        child: Container(
                          width: 110,
                          margin: EdgeInsets.only(right: i < docs.length - 1 ? 10 : 0),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: imgUrl != null
                                  ? Image.network(imgUrl, height: 70, width: 110, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(height: 70, color: AppTheme.surface,
                                          child: const Icon(Iconsax.gallery, color: AppTheme.textMuted, size: 28)))
                                  : Container(height: 70, color: AppTheme.surface,
                                      child: const Icon(Iconsax.gallery, color: AppTheme.textMuted, size: 28)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(nombre, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('\$${precio.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                                Text(municipio, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.textMuted)),
                              ]),
                            ),
                          ]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // ── Consejos de Ura IA ──
            Text('Consejos de Ura IA 🌿', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Comprar local fortalece a nuestros productores y nuestra región.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                      const SizedBox(height: 6),
                      Text('¡Gracias por apoyar lo nuestro! 💚',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    ]),
                  ),
                  _tipCard(Iconsax.shield_tick, 'Compra segura', 'Tus pagos están\nprotegidos', const Color(0xFF0891B2)),
                  const SizedBox(width: 10),
                  _tipCard(Iconsax.tree, '100% Local', 'Apoya a nuestros\nproductores', const Color(0xFF16A34A)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String prompt) {
    return GestureDetector(
      onTap: () => _sendMessage(prompt),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ),
    );
  }

  Widget _tipCard(IconData icon, String title, String sub, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted, height: 1.3), maxLines: 2),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CHAT LIST
  // ═══════════════════════════════════════════════════════════

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildBubble(_messages[index], index),
    );
  }

  Widget _buildBubble(_ChatMessage msg, int index) {
    // Loading dots
    if (msg.isLoading && msg.text.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 60),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _aiAvatar(),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: _aiBubbleDecoration(),
                child: _buildAnimatedDots(),
              ),
            ],
          ),
        ),
      );
    }

    final isUser = msg.isUser;
    final isLast = index == _messages.length - 1;
    final isError = msg.isError;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(bottom: 4, left: isUser ? 50 : 0, right: isUser ? 0 : 40),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[_aiAvatar(), const SizedBox(width: 8)],
                Flexible(
                  child: GestureDetector(
                    onLongPress: !isUser && msg.text.isNotEmpty ? () => _showMessageActions(msg.text) : null,
                    onDoubleTap: msg.text.isNotEmpty ? () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      HapticFeedback.lightImpact();
                      _showSnack('Copiado', AppTheme.green);
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: isUser ? _userBubbleDecoration() : _aiBubbleDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image preview
                          if (isUser && msg.imageBytes != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(msg.imageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Text content
                          if (isUser)
                            Text(msg.text, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.primary, height: 1.45))
                          else
                            _buildRichMarkdown(msg.text),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Timestamp + streaming indicator
        Padding(
          padding: EdgeInsets.only(left: isUser ? 0 : 36, right: isUser ? 4 : 0, bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted),
              ),
              if (!isUser && _isSending && isLast) ...[
                const SizedBox(width: 6),
                SizedBox(width: 8, height: 8, child: CircularProgressIndicator(
                  color: AppTheme.primary.withValues(alpha: 0.5), strokeWidth: 1.5,
                )),
              ],
            ],
          ),
        ),
        // Error retry button
        if (isError && isLast)
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 8),
            child: GestureDetector(
              onTap: _retryLastMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Iconsax.refresh, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Text('Reintentar', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                ]),
              ),
            ),
          ),
        // Follow-up suggestions
        if (!isUser && isLast && !_isSending && !isError && msg.text.isNotEmpty)
          _buildSuggestionChips(_getSuggestions(msg.text)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DECORATIONS
  // ═══════════════════════════════════════════════════════════

  Widget _aiAvatar() {
    return Container(
      width: 28, height: 28,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1C3320), Color(0xFF0F1E12)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Iconsax.cpu, color: AppTheme.primary, size: 14),
    );
  }

  BoxDecoration _userBubbleDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1C3320), Color(0xFF0F1E12)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18), topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
      ),
      boxShadow: [BoxShadow(
        color: const Color(0xFF1C3320).withValues(alpha: 0.25),
        blurRadius: 12, offset: const Offset(0, 3),
      )],
    );
  }

  BoxDecoration _aiBubbleDecoration() {
    return BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18), topRight: Radius.circular(18),
        bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
      ),
      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25), width: 1),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 10, offset: const Offset(0, 2),
      )],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MARKDOWN RENDERING
  // ═══════════════════════════════════════════════════════════

  Widget _buildRichMarkdown(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Headers ### or ##
      if (line.startsWith('### ')) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
        widgets.add(Text(
          line.substring(4),
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.4),
        ));
        widgets.add(const SizedBox(height: 4));
        continue;
      }
      if (line.startsWith('## ')) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
        widgets.add(Text(
          line.substring(3),
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.4),
        ));
        widgets.add(const SizedBox(height: 4));
        continue;
      }

      // Bullet points
      if (line.trimLeft().startsWith('• ') || line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
        final indent = line.length - line.trimLeft().length;
        final content = line.trimLeft().substring(2);
        widgets.add(Padding(
          padding: EdgeInsets.only(left: indent > 0 ? 16.0 : 0, top: 3, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5, height: 5,
                margin: const EdgeInsets.only(top: 7, right: 8),
                decoration: const BoxDecoration(color: AppTheme.textSecondary, shape: BoxShape.circle),
              ),
              Expanded(child: _buildInlineMarkdown(content)),
            ],
          ),
        ));
        continue;
      }

      // Numbered list
      final numMatch = RegExp(r'^(\d+)\.\s(.+)$').firstMatch(line.trim());
      if (numMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22, height: 22,
                margin: const EdgeInsets.only(right: 8, top: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(numMatch.group(1)!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ),
              Expanded(child: _buildInlineMarkdown(numMatch.group(2)!)),
            ],
          ),
        ));
        continue;
      }

      // Empty line = spacing
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Regular text with inline formatting
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: _buildInlineMarkdown(line),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInlineMarkdown(String text) {
    final spans = <InlineSpan>[];
    // Match **bold**, *italic*, `code`, and $price
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|(\$[\d,.]+)');
    int lastEnd = 0;

    final baseStyle = GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary, height: 1.5);

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        // `code`
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(match.group(3)!,
                style: GoogleFonts.firaCode(fontSize: 12.5, color: const Color(0xFFE11D48))),
          ),
        ));
      } else if (match.group(4) != null) {
        // $price — highlight
        spans.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(fontWeight: FontWeight.w800, color: AppTheme.green),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    if (spans.isEmpty) {
      return Text(text, style: baseStyle);
    }

    return RichText(text: TextSpan(children: spans));
  }

  // ═══════════════════════════════════════════════════════════
  // SUGGESTIONS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSuggestionChips(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 12, right: 16),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: suggestions.map((s) => GestureDetector(
          onTap: () => _sendMessage(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          ),
        )).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TYPING DOTS
  // ═══════════════════════════════════════════════════════════

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotsAnim,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          final t = ((_dotsAnim.value - delay) % 1.0).clamp(0.0, 1.0);
          final y = -4.0 * (1 - (2 * t - 1) * (2 * t - 1));
          return Container(
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: Transform.translate(
              offset: Offset(0, y),
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.4 + (0.4 * (1 - t))),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INPUT BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botón para subir fotos
          GestureDetector(
            onTap: _isSending ? null : _analyzeImage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.camera, color: AppTheme.primary, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_isSending,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4, minLines: 1,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta aquí...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (t) => _sendMessage(t),
            ),
          ),
          const SizedBox(width: 10),
          // Botón enviar — cuadrado redondeado verde
          GestureDetector(
            onTap: _isSending ? null : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _isSending ? AppTheme.textMuted : AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isSending ? null : [BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10, offset: const Offset(0, 3),
                )],
              ),
              child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
