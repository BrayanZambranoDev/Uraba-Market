import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'services/cloudinary_service.dart';
import 'package:iconsax/iconsax.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String currentUserName;
  final String? conversationId;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.currentUserName,
    this.conversationId,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Audio
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isSendingAudio = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _currentlyPlayingUrl;
  PlayerState _playerState = PlayerState.stopped;

  // Estado general
  String? _conversationId;
  bool _isLoading = true;
  bool _isSendingImage = false;
  bool _showScrollToBottom = false;
  bool _showEmojiPanel = false;
  int _lastMessageCount = 0;

  // Reply
  Map<String, dynamic>? _replyTo; // {text, senderName, tipo}

  // Typing indicator
  Timer? _typingTimer;
  bool _otherUserTyping = false;
  StreamSubscription<DocumentSnapshot>? _convSub;

  // Ticks de lectura
  Timestamp? _lastReadOther; // cuándo leyó el otro usuario por última vez

  // Info del otro usuario
  String _otherUserStatus = 'Cargando...';
  String? _otherUserPhotoURL;

  // Panel de emojis rápidos
  static const _quickEmojis = [
    '👍','❤️','😂','😮','😢','🙏','🔥','⭐',
    '✅','💯','🎉','😊','👌','💪','🌿','🥑',
    '🍌','🥭','🍅','🧺','🎨','🛒','💰','📦',
  ];

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (widget.initialMessage != null) {
      _msgController.text = widget.initialMessage!;
    }
    _scrollController.addListener(_onScroll);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _currentlyPlayingUrl = null);
    });
    _msgController.addListener(_onTypingChanged);
    _initConversation();
    _loadOtherUserInfo();
  }

  void _onTypingChanged() {
    if (_conversationId == null || _user == null) return;
    // Notifica "está escribiendo" y reinicia el timer de pausa
    _firestoreService.setTyping(_conversationId!, _user!.uid, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_conversationId != null && _user != null) {
        _firestoreService.setTyping(_conversationId!, _user!.uid, false);
      }
    });
  }

  void _subscribeConversation() {
    if (_conversationId == null) return;
    _convSub?.cancel();
    _convSub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId!)
        .snapshots()
        .listen((snap) {
      if (!mounted || !snap.exists) return;
      final data = snap.data()!;
      // Typing del otro usuario
      final typing = data['typing'] as Map<String, dynamic>? ?? {};
      final otherTypingTs = typing[widget.otherUserId] as Timestamp?;
      final isTyping = otherTypingTs != null &&
          DateTime.now().difference(otherTypingTs.toDate()).inSeconds < 5;
      // Última lectura del otro usuario
      final lastRead = data['lastRead'] as Map<String, dynamic>? ?? {};
      final otherRead = lastRead[widget.otherUserId] as Timestamp?;
      // Solo reconstruir si algo cambió visualmente
      if (_otherUserTyping != isTyping ||
          _lastReadOther?.millisecondsSinceEpoch !=
              otherRead?.millisecondsSinceEpoch) {
        setState(() {
          _otherUserTyping = isTyping;
          _lastReadOther = otherRead;
        });
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120;
    if (_showScrollToBottom == atBottom) {
      setState(() => _showScrollToBottom = !atBottom);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _loadOtherUserInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      _otherUserPhotoURL = data['photoURL'] as String?;
      final lastLogin = data['lastLogin'] as Timestamp?;
      String status = '';
      if (lastLogin != null) {
        final diff = DateTime.now().difference(lastLogin.toDate());
        if (diff.inMinutes < 5) {
          status = 'En línea ahora';
        } else if (diff.inMinutes < 60) {
          status = 'Activo hace ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          status = 'Activo hace ${diff.inHours}h';
        } else if (diff.inDays == 1) {
          status = 'Activo ayer';
        } else {
          status = 'Activo hace ${diff.inDays} días';
        }
      }
      if (mounted) setState(() => _otherUserStatus = status);
    } catch (_) {
      if (mounted) setState(() => _otherUserStatus = '');
    }
  }

  void _initConversation() async {
    if (_user == null) return;
    _conversationId ??= await _firestoreService.getOrCreateConversation(
      userId1: _user!.uid,
      userName1: widget.currentUserName,
      userId2: widget.otherUserId,
      userName2: widget.otherUserName,
    );
    if (_conversationId != null) {
      _firestoreService.markConversationRead(_conversationId!, _user!.uid);
      _subscribeConversation();
    }
    if (mounted) setState(() => _isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) _scrollToBottom(animated: false);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _msgController.removeListener(_onTypingChanged);
    _msgController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _typingTimer?.cancel();
    _convSub?.cancel();
    // Limpiar estado typing al salir
    if (_conversationId != null && _user != null) {
      _firestoreService.setTyping(_conversationId!, _user!.uid, false);
    }
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── ENVIAR TEXTO ──────────────────────────────────────────────────
  Future<void> _sendMessage({String? text}) async {
    final txt = text ?? _msgController.text.trim();
    if (txt.isEmpty || _conversationId == null || _user == null) return;
    if (text == null) _msgController.clear();
    final replyData = _replyTo;
    setState(() { _showEmojiPanel = false; _replyTo = null; });
    _typingTimer?.cancel();
    _firestoreService.setTyping(_conversationId!, _user!.uid, false);
    await _firestoreService.sendMessage(
      conversationId: _conversationId!,
      senderId: _user!.uid,
      senderName: widget.currentUserName,
      text: txt,
      recipientId: widget.otherUserId,
      replyTo: replyData,
    );
    Future.delayed(const Duration(milliseconds: 150), () => _scrollToBottom());
  }

  // ── ENVIAR IMAGEN / CÁMARA ────────────────────────────────────────
  Future<void> _pickMedia(ImageSource source) async {
    Navigator.pop(context); // cierra bottom sheet
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (picked == null || _conversationId == null || _user == null) return;
    setState(() => _isSendingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await CloudinaryService.uploadImage(bytes, folder: 'chats');
      await _firestoreService.sendMessage(
        conversationId: _conversationId!,
        senderId: _user!.uid,
        senderName: widget.currentUserName,
        text: '',
        recipientId: widget.otherUserId,
        tipo: 'imagen',
        imagenUrl: url,
      );
      Future.delayed(
          const Duration(milliseconds: 150), () => _scrollToBottom());
    } catch (_) {
      if (!mounted) return;
      _showSnack('No se pudo enviar la imagen', AppTheme.error);
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  void _showMediaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.radiusXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: AppTheme.radiusFull,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _mediaOption(
                  icon: Iconsax.gallery,
                  label: 'Galería',
                  color: AppTheme.primary,
                  onTap: () => _pickMedia(ImageSource.gallery),
                ),
                _mediaOption(
                  icon: Iconsax.camera,
                  label: 'Cámara',
                  color: AppTheme.green,
                  onTap: () => _pickMedia(ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _mediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusL,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ── GRABACIÓN DE AUDIO ────────────────────────────────────────────
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showSnack('Permiso de micrófono denegado', AppTheme.error);
      return;
    }
    final path =
        '${Directory.systemTemp.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopAndSendAudio() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    if (mounted) setState(() { _isRecording = false; _isSendingAudio = true; });
    if (path == null || _conversationId == null || _user == null) {
      if (mounted) setState(() => _isSendingAudio = false);
      return;
    }
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final url = await CloudinaryService.uploadAudio(bytes, folder: 'chats_audio');
      await _firestoreService.sendMessage(
        conversationId: _conversationId!,
        senderId: _user!.uid,
        senderName: widget.currentUserName,
        text: 'Audio',
        recipientId: widget.otherUserId,
        tipo: 'audio',
        imagenUrl: url,
        duracion: _recordingSeconds,
      );
      file.deleteSync(); // limpiar archivo temporal
      Future.delayed(
          const Duration(milliseconds: 150), () => _scrollToBottom());
    } catch (_) {
      _showSnack('No se pudo enviar el audio', AppTheme.error);
    } finally {
      if (mounted) setState(() => _isSendingAudio = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    if (path != null) {
      try { File(path).deleteSync(); } catch (_) {}
    }
    if (mounted) setState(() { _isRecording = false; _recordingSeconds = 0; });
  }

  // ── REPRODUCIR AUDIO ──────────────────────────────────────────────
  Future<void> _toggleAudio(String url) async {
    if (_currentlyPlayingUrl == url &&
        _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      setState(() => _currentlyPlayingUrl = null);
    } else {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingUrl = url);
      await _audioPlayer.play(UrlSource(url));
    }
  }

  // ── LONG PRESS ────────────────────────────────────────────────────
  void _onLongPressMessage(String messageId, String texto, bool isMe,
      bool eliminado, String senderName) {
    if (eliminado) return;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.radiusXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: AppTheme.radiusFull,
              ),
            ),
            // Responder
            _msgAction(
              icon: Iconsax.undo,
              label: 'Responder',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyTo = {
                  'text': texto.isNotEmpty ? texto : 'Imagen',
                  'senderName': senderName,
                });
              },
            ),
            if (texto.isNotEmpty && texto != 'Audio' && texto != 'Imagen')
              _msgAction(
                icon: Iconsax.copy,
                label: 'Copiar',
                color: AppTheme.textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: texto));
                  _showSnack('Copiado al portapapeles',
                      AppTheme.textSecondary,
                      duration: 2);
                },
              ),
            if (isMe)
              _msgAction(
                icon: Iconsax.trash,
                label: 'Eliminar mensaje',
                color: AppTheme.error,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _firestoreService.deleteMessage(
                    conversationId: _conversationId!,
                    messageId: messageId,
                  );
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _msgAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppTheme.radiusM,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color, {int duration = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.plusJakartaSans(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
      margin: const EdgeInsets.all(12),
      duration: Duration(seconds: duration),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFF060A07);
  static const _cardBg = Color(0xFF0D1A0E);
  static const _inputBg = Color(0xFF111A12);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  _isLoading ? _buildLoading() : _buildMessages(),
                  if (_showScrollToBottom)
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _scrollToBottom(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.shadowMd,
                            border:
                                Border.all(color: AppTheme.border, width: 1),
                          ),
                          child: const Icon(
                              Iconsax.arrow_down,
                              color: AppTheme.primary,
                              size: 24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_replyTo != null) _buildReplyBar(),
            _isRecording ? _buildRecordingBar() : _buildInput(),
            if (_showEmojiPanel) _buildEmojiPanel(),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final inicial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';
    final isOnline = _otherUserStatus == 'En línea ahora';

    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Iconsax.arrow_left,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.green, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.green.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _otherUserPhotoURL != null
                      ? CachedNetworkImage(
                          imageUrl: _otherUserPhotoURL!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: _inputBg,
                            child: Center(
                              child: Text(inicial,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary)),
                            ),
                          ),
                        )
                      : Container(
                          color: _inputBg,
                          child: Center(
                            child: Text(inicial,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary)),
                          )),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bg, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                if (_otherUserTyping)
                  Row(children: [
                    Text('Escribiendo',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.green)),
                    const SizedBox(width: 4),
                    _TypingDots(),
                  ])
                else if (_otherUserStatus.isNotEmpty)
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.green : AppTheme.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(_otherUserStatus,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.green)),
                  ]),
              ],
            ),
          ),
          Icon(Iconsax.call,
              color: Colors.white.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 16),
          Icon(Iconsax.video,
              color: Colors.white.withValues(alpha: 0.8), size: 22),
          const SizedBox(width: 16),
          Icon(Iconsax.more,
              color: Colors.white.withValues(alpha: 0.8), size: 22),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary));
  }

  // ── MENSAJES ──────────────────────────────────────────────────────
  Widget _buildMessages() {
    if (_conversationId == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Iconsax.message,
              size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 8),
          Text('Envía el primer mensaje', style: AppTheme.bodyMuted),
        ]),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMessages(_conversationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.length > _lastMessageCount && _lastMessageCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final atBottom = _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 200;
              if (atBottom) _scrollToBottom();
            }
          });
        }
        _lastMessageCount = docs.length;

        if (docs.isEmpty) {
          return Align(
            alignment: const Alignment(0, -0.1),
            child: Opacity(
              opacity: 0.20,
              child: Image.asset('imagen conversaciones.png',
                  width: 260, fit: BoxFit.contain),
            ),
          );
        }

        final items = <dynamic>[];
        DateTime? lastDate;
        for (final doc in docs) {
          final msg = doc.data() as Map<String, dynamic>;
          final ts = msg['timestamp'] as Timestamp?;
          if (ts != null) {
            final date = ts.toDate();
            final day = DateTime(date.year, date.month, date.day);
            if (lastDate == null || day != lastDate) {
              items.add(day);
              lastDate = day;
            }
          }
          items.add(doc);
        }

        return Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.15),
              child: Opacity(
                opacity: 0.15,
                child: Image.asset('imagen conversaciones.png',
                    width: 260, fit: BoxFit.contain),
              ),
            ),
            ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            if (item is DateTime) return _buildDateSeparator(item);
            final doc = item as QueryDocumentSnapshot;
            final msg = doc.data() as Map<String, dynamic>;
            final isMe = msg['senderId'] == _user?.uid;
            bool isLast = true;
            if (i + 1 < items.length &&
                items[i + 1] is QueryDocumentSnapshot) {
              final nextMsg =
                  (items[i + 1] as QueryDocumentSnapshot).data()
                      as Map<String, dynamic>;
              isLast = nextMsg['senderId'] != msg['senderId'];
            }
            return GestureDetector(
              onLongPress: () => _onLongPressMessage(
                  doc.id,
                  msg['texto'] ?? '',
                  isMe,
                  msg['eliminado'] == true,
                  msg['senderName'] as String? ?? ''),
              child: _buildBubble(msg, isMe, isLast: isLast),
            );
          },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(date.year, date.month, date.day);
    String label;
    if (day == today) {
      label = 'Hoy';
    } else if (day == yesterday) {
      label = 'Ayer';
    } else {
      const months = ['','ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      label = '${date.day} ${months[date.month]} ${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(child: Divider(
            color: Colors.white.withValues(alpha: 0.12), thickness: 0.6)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.4))),
        ),
        Expanded(child: Divider(
            color: Colors.white.withValues(alpha: 0.12), thickness: 0.6)),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe,
      {bool isLast = true}) {
    final texto = msg['texto'] ?? '';
    final tipo = msg['tipo'] as String? ?? 'texto';
    final mediaUrl = msg['imagenUrl'] as String?;
    final eliminado = msg['eliminado'] == true;
    final duracion = (msg['duracion'] as num?)?.toInt() ?? 0;
    final timestamp = msg['timestamp'] as Timestamp?;
    String hora = '';
    if (timestamp != null) {
      final dt = timestamp.toDate();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour < 12 ? 'AM' : 'PM';
      hora = '$h:${dt.minute.toString().padLeft(2, '0')} $period';
    }

    final bubbleColor = isMe ? AppTheme.primary : const Color(0xFF162218);
    final textColor = isMe ? const Color(0xFFE8F0E9) : Colors.white;
    final replyTo = msg['replyTo'] as Map<String, dynamic>?;

    // Ticks de lectura: doble naranja si el otro leyó después del timestamp
    final isRead = isMe &&
        timestamp != null &&
        _lastReadOther != null &&
        timestamp.compareTo(_lastReadOther!) <= 0;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            bottom: isLast ? 8 : 2,
            left: isMe ? 56 : 0,
            right: isMe ? 0 : 56),
        decoration: eliminado
            ? null
            : BoxDecoration(
                color: tipo == 'imagen' ? Colors.transparent : bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : Radius.circular(isLast ? 4 : 18),
                  bottomRight: isMe
                      ? Radius.circular(isLast ? 4 : 18)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        child: eliminado
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(18)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Iconsax.forbidden,
                      size: 13, color: AppTheme.textDisabled),
                  const SizedBox(width: 6),
                  Text('Mensaje eliminado',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textDisabled)),
                ]),
              )
            : tipo == 'imagen' && mediaUrl != null
                ? _buildImageBubble(mediaUrl, hora, isMe)
                : tipo == 'audio' && mediaUrl != null
                    ? _buildAudioBubble(mediaUrl, hora, isMe, duracion, textColor, bubbleColor)
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Cita de reply ──
                            if (replyTo != null) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : AppTheme.primary.withValues(alpha: 0.08),
                                  borderRadius: AppTheme.radiusM,
                                  border: Border(
                                    left: BorderSide(
                                      color: isMe
                                          ? Colors.white
                                          : AppTheme.primary,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      replyTo['senderName'] as String? ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isMe
                                              ? Colors.white
                                              : AppTheme.primary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      replyTo['text'] as String? ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: isMe
                                              ? Colors.white70
                                              : AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // ── Texto del mensaje ──
                            Text(texto,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, color: textColor)),
                            const SizedBox(height: 3),
                            // ── Hora + ticks ──
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(hora,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white70
                                            : AppTheme.textMuted)),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    isRead
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 14,
                                    color: isRead
                                        ? AppTheme.orangeLight
                                        : const Color(0xFFE8F0E9).withValues(alpha: 0.5),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildImageBubble(String url, String hora, bool isMe) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
    );
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _FullscreenImageScreen(url: url)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Hero(
              tag: url,
              child: CachedNetworkImage(
                imageUrl: url,
                width: 220,
                height: 260,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 220,
                  height: 260,
                  color: AppTheme.inputBg,
                  child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary)),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 220,
                  height: 260,
                  color: AppTheme.inputBg,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppTheme.textMuted),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: AppTheme.radiusFull,
                ),
                child: Text(hora,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BARRA DE REPLY ────────────────────────────────────────────────
  Widget _buildReplyBar() {
    final reply = _replyTo!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          left: const BorderSide(color: AppTheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reply['senderName'] as String,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cacao)),
                const SizedBox(height: 2),
                Text(reply['text'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyTo = null),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.inputBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.close_circle,
                  size: 16, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBubble(String url, String hora, bool isMe, int duracion,
      Color textColor, Color bubbleColor) {
    final isPlaying =
        _currentlyPlayingUrl == url && _playerState == PlayerState.playing;
    final min = (duracion ~/ 60).toString().padLeft(2, '0');
    final sec = (duracion % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _toggleAudio(url),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Iconsax.pause : Iconsax.play,
                color: isMe ? Colors.white : AppTheme.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pseudo-waveform
              Row(
                children: List.generate(18, (i) {
                  final h = (i % 3 == 0
                      ? 16.0
                      : i % 2 == 0
                          ? 10.0
                          : 6.0);
                  return Container(
                    width: 3,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withValues(alpha: isPlaying ? 1.0 : 0.6)
                          : AppTheme.primary.withValues(alpha: isPlaying ? 1.0 : 0.5),
                      borderRadius: AppTheme.radiusFull,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('$min:$sec',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isMe ? Colors.white70 : AppTheme.textMuted)),
                  const SizedBox(width: 12),
                  Text(hora,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: isMe ? Colors.white60 : AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BARRA DE GRABACIÓN ────────────────────────────────────────────
  Widget _buildRecordingBar() {
    final min = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: _bg,
      child: Row(
        children: [
          // Cancelar
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.trash,
                  color: AppTheme.error, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Indicador grabando
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: AppTheme.error, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('Grabando  $min:$sec',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          // Enviar
          GestureDetector(
            onTap: _stopAndSendAudio,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.orangeGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowOrangeList,
              ),
              child: const Icon(Iconsax.send_1,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── INPUT ─────────────────────────────────────────────────────────
  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Emoji button
            _inputIconBtn(
              icon: _showEmojiPanel
                  ? Iconsax.keyboard
                  : Iconsax.emoji_happy,
              color: const Color(0xFFFBBF24),
              onTap: () => setState(() => _showEmojiPanel = !_showEmojiPanel),
            ),
            const SizedBox(width: 4),
            // Media button
            _inputIconBtn(
              icon: _isSendingImage
                  ? Iconsax.clock
                  : Iconsax.attach_circle,
              color: AppTheme.green,
              onTap: _isSendingImage ? null : _showMediaSheet,
            ),
            const SizedBox(width: 4),
            // Campo de texto
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08), width: 0.8),
                ),
                child: TextField(
                  controller: _msgController,
                  style: AppTheme.body,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: AppTheme.bodyMuted,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Micrófono / Enviar
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _msgController,
              builder: (_, val, __) {
                final hasText = val.text.trim().isNotEmpty;
                if (hasText) {
                  return GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.green.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Iconsax.send_1,
                          color: Colors.white, size: 20),
                    ),
                  );
                }
                // Sin texto → botón micrófono
                return GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopAndSendAudio(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.green.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSendingAudio
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Iconsax.microphone,
                            color: Colors.white, size: 20),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputIconBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  // ── PANEL DE EMOJIS ───────────────────────────────────────────────
  Widget _buildEmojiPanel() {
    return Container(
      height: 200,
      color: _cardBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reacciones rápidas',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _quickEmojis.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _sendMessage(text: _quickEmojis[i]),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: AppTheme.radiusM,
                  ),
                  child: Center(
                    child: Text(_quickEmojis[i],
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget de puntos animados "Escribiendo..."
// ─────────────────────────────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (t - i * 0.2).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                .clamp(0.3, 1.0);
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppTheme.orangeLight.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla fullscreen de imagen
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenImageScreen extends StatelessWidget {
  final String url;
  const _FullscreenImageScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}
