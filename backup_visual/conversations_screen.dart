import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'utils/shimmer_box.dart';
import 'chat_screen.dart';
import 'package:iconsax/iconsax.dart';

enum _Filter { todos, noLeidos, favoritos, grupos }

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  _Filter _filter = _Filter.todos;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF2563EB),
      const Color(0xFFDB2777),
      const Color(0xFF0891B2),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: Text('Inicia sesión')),
      );
    }
    final firestoreService = FirestoreService();

    const _bg = Color(0xFF060A07);

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: _buildBottomNav(context),
      body: Column(children: [
        // ── Header (mismo fondo que toda la pantalla) ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.arrow_left,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Mensajes',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text('Tus conversaciones',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ]),
                ),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.edit,
                      color: Colors.white, size: 18),
                ),
              ]),
              const SizedBox(height: 14),
              // Barra de búsqueda — ícono y texto dentro del mismo container
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const SizedBox(width: 12),
                  Icon(Iconsax.search_normal,
                      color: Colors.white.withValues(alpha: 0.45), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar conversaciones...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.38)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // Tabs de filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _filterChip('Todos', _Filter.todos),
                  const SizedBox(width: 8),
                  _filterChip('No leídos', _Filter.noLeidos,
                      icon: Icons.circle, iconSize: 8),
                  const SizedBox(width: 8),
                  _filterChip('Favoritos', _Filter.favoritos,
                      icon: Iconsax.star5, iconSize: 13),
                  const SizedBox(width: 8),
                  _filterChip('Grupos', _Filter.grupos,
                      icon: Iconsax.people, iconSize: 14),
                ]),
              ),
            ]),
          ),
        ),

        // ── Lista ──
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getConversations(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, __) => const ShimmerListTile(),
                );
              }

              var docs = snapshot.data?.docs ?? [];

              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final participantes = data['participantes'] as Map<String, dynamic>? ?? {};
                  return participantes.values.any((v) =>
                      v.toString().toLowerCase().contains(_searchQuery));
                }).toList();
              }

              if (_filter == _Filter.noLeidos) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final counts = data['unreadCounts'] as Map<String, dynamic>?;
                  return ((counts?[user.uid] as num?)?.toInt() ?? 0) > 0;
                }).toList();
              }

              if (docs.isEmpty) {
                return _buildEmpty();
              }

              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async =>
                    await Future.delayed(const Duration(milliseconds: 300)),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _buildTile(context, docs[i].id,
                                docs[i].data() as Map<String, dynamic>, user.uid),
                          ),
                          childCount: docs.length,
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: _buildPromo()),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, _Filter value,
      {IconData? icon, double iconSize = 12}) {
    final selected = _filter == value;
    final color = selected ? Colors.white : Colors.white70;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      ),
    );
  }

  Widget _buildPromo() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('imagen mensajes.jpg', width: 320, fit: BoxFit.contain),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.72,
                  colors: [Colors.transparent, const Color(0xFF060A07)],
                  stops: const [0.52, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Image.asset(
        'imagen mensajes.jpg',
        width: 280,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    Widget _navItem(IconData icon, String label, {bool active = false, VoidCallback? onTap}) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap ?? () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: active ? AppTheme.primary : AppTheme.textSecondary, size: 22),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.plusJakartaSans(
                height: 1.0, fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppTheme.primary : AppTheme.textSecondary)),
          ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060A07),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _navItem(Iconsax.home, 'Inicio'),
            _navItem(Iconsax.search_normal, 'Explorar'),
            // Centro: Mensajes activo con icono personalizado
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 3))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset('mensajes icono.png',
                          color: AppTheme.primary,
                          colorBlendMode: BlendMode.multiply),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text('Mensajes', style: GoogleFonts.plusJakartaSans(
                      height: 1.0, fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
                ]),
              ),
            ),
            _navItem(Iconsax.receipt_2, 'Pedidos'),
            _navItem(Iconsax.user, 'Perfil'),
          ]),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String convId,
      Map<String, dynamic> data, String currentUserId) {
    final participantes = data['participantes'] as Map<String, dynamic>? ?? {};
    final participantIds = List<String>.from(data['participantIds'] ?? []);
    final otherUserId = participantIds.firstWhere(
        (id) => id != currentUserId, orElse: () => '');
    final otherUserName = participantes[otherUserId]?.toString() ?? 'Usuario';
    final currentUserName = participantes[currentUserId]?.toString() ?? 'Yo';

    final ultimoMensaje = data['ultimoMensaje']?.toString() ?? '';
    final ultimoTimestamp = data['ultimoTimestamp'] as Timestamp?;
    final horaStr = ultimoTimestamp != null
        ? '${ultimoTimestamp.toDate().hour}:${ultimoTimestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    final counts = data['unreadCounts'] as Map<String, dynamic>?;
    final unreadCount = (counts?[currentUserId] as num?)?.toInt() ?? 0;
    final isUnread = unreadCount > 0;
    final avatarColor = _avatarColor(otherUserName);
    final initial = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(ChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          currentUserName: currentUserName,
          conversationId: convId,
        )),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1A0E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppTheme.primary.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
            width: isUnread ? 1.5 : 0.8,
          ),
        ),
        child: Row(children: [
          // Avatar con punto online
          Stack(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: avatarColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text(initial,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: avatarColor)),
              ),
            ),
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D1A0E), width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          // Nombre + último mensaje
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(otherUserName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text(ultimoMensaje,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isUnread ? AppTheme.textSecondary : AppTheme.textSecondary,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          // Hora + badge
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(horaStr,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isUnread ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400)),
            if (isUnread) ...[
              const SizedBox(height: 5),
              Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}
