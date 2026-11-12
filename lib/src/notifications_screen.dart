import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'orders_screen.dart';
import 'conversations_screen.dart';
import 'package:iconsax/iconsax.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver notificaciones')),
      );
    }

    const bg = Color(0xFF0A0F0A);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        Container(
          color: bg,
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
                    Text('Notificaciones 🌿', style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Tu actividad reciente', style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                  ]),
                ),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.setting_4, color: Colors.white.withValues(alpha: 0.7), size: 18),
                ),
              ]),
            ),
          ),
        ),
        // Tabs
        Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            _tabChip('Todas', true), const SizedBox(width: 8),
            _tabChip('Pedidos', false), const SizedBox(width: 8),
            _tabChip('Mensajes', false),
          ]),
        ),
        Expanded(child: _NotificationsList(userId: user.uid)),
      ]),
    );
  }

  Widget _tabChip(String label, bool selected) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55))),
  );
}

// ─── Lista de notificaciones ───────────────────────────────────────────────────
class _NotificationsList extends StatelessWidget {
  final String userId;
  const _NotificationsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_NotifItem>>(
      future: _loadNotifications(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final items = snap.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.notification,
                      size: 38, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Sin notificaciones', style: AppTheme.subtitle),
                const SizedBox(height: 6),
                Text('Aquí verás pedidos, mensajes y más',
                    style: AppTheme.bodyMuted),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 300)),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 32 + MediaQuery.of(context).padding.bottom),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _NotifCard(item: items[i], context: ctx),
          ),
        );
      },
    );
  }

  Future<List<_NotifItem>> _loadNotifications(String uid) async {
    final db = FirebaseFirestore.instance;
    final items = <_NotifItem>[];

    // Pedidos como comprador
    final asBuyer = await db
        .collection('pedidos')
        .where('compradorId', isEqualTo: uid)
        .orderBy('fechaCreacion', descending: true)
        .limit(15)
        .get();

    for (final doc in asBuyer.docs) {
      final d = doc.data();
      final estado = d['estado'] as String? ?? 'pendiente';
      final producto = d['productoNombre'] as String? ?? 'Producto';
      final ts = d['fechaCreacion'] as Timestamp?;
      items.add(_NotifItem(
        type: _NotifType.order,
        title: _labelForEstado(estado, asBuyer: true),
        subtitle: producto,
        timestamp: ts,
        docId: doc.id,
        estado: estado,
      ));
    }

    // Pedidos como vendedor
    final asVendor = await db
        .collection('pedidos')
        .where('vendedorId', isEqualTo: uid)
        .orderBy('fechaCreacion', descending: true)
        .limit(15)
        .get();

    for (final doc in asVendor.docs) {
      final d = doc.data();
      final estado = d['estado'] as String? ?? 'pendiente';
      final producto = d['productoNombre'] as String? ?? 'Producto';
      final ts = d['fechaCreacion'] as Timestamp?;
      items.add(_NotifItem(
        type: _NotifType.order,
        title: _labelForEstado(estado, asBuyer: false),
        subtitle: producto,
        timestamp: ts,
        docId: doc.id,
        estado: estado,
      ));
    }

    // Conversaciones con mensajes no leídos
    final convSnap = await db
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .orderBy('ultimoTimestamp', descending: true)
        .limit(10)
        .get();

    for (final doc in convSnap.docs) {
      final d = doc.data();
      final counts = d['unreadCounts'] as Map<String, dynamic>?;
      final unread = (counts?[uid] as num?)?.toInt() ?? 0;
      if (unread > 0) {
        final participantes = d['participantes'] as Map<String, dynamic>? ?? {};
        final ids = List<String>.from(d['participantIds'] ?? []);
        final otherId = ids.firstWhere((id) => id != uid, orElse: () => '');
        final otherName = participantes[otherId]?.toString() ?? 'Alguien';
        final ultimoMensaje = d['ultimoMensaje'] as String? ?? '';
        final ts = d['ultimoTimestamp'] as Timestamp?;
        items.add(_NotifItem(
          type: _NotifType.message,
          title: '$otherName te envió ${unread == 1 ? 'un mensaje' : '$unread mensajes'}',
          subtitle: ultimoMensaje,
          timestamp: ts,
          docId: doc.id,
          estado: '',
        ));
      }
    }

    // Ordenar por timestamp descendente
    items.sort((a, b) {
      final ta = a.timestamp?.millisecondsSinceEpoch ?? 0;
      final tb = b.timestamp?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    return items;
  }

  String _labelForEstado(String estado, {required bool asBuyer}) {
    if (asBuyer) {
      switch (estado) {
        case 'pendiente':
          return 'Pedido enviado — esperando confirmación';
        case 'confirmado':
          return 'Tu pedido fue confirmado';
        case 'entregado':
          return 'Pedido entregado — ¡a disfrutar!';
        case 'cancelado':
          return 'Pedido cancelado';
        default:
          return 'Pedido actualizado';
      }
    } else {
      switch (estado) {
        case 'pendiente':
          return 'Nuevo pedido recibido';
        case 'confirmado':
          return 'Confirmaste un pedido';
        case 'entregado':
          return 'Pedido marcado como entregado';
        case 'cancelado':
          return 'Pedido cancelado';
        default:
          return 'Pedido actualizado';
      }
    }
  }
}

// ─── Tarjeta ───────────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final _NotifItem item;
  final BuildContext context;
  const _NotifCard({required this.item, required this.context});

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    final d = ts.toDate();
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext buildCtx) {
    final isMessage = item.type == _NotifType.message;
    final iconData = isMessage
        ? Iconsax.message
        : _iconForEstado(item.estado);
    final color = isMessage ? const Color(0xFF8B5CF6) : _colorForEstado(item.estado);

    return GestureDetector(
      onTap: () {
        if (isMessage) {
          Navigator.push(buildCtx,
              AppTheme.pageRoute(const ConversationsScreen()));
        } else {
          Navigator.push(buildCtx,
              AppTheme.pageRoute(const OrdersScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131C13),
          borderRadius: AppTheme.radiusL,
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)],
            ),
            child: Icon(iconData, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMessage ? const Color(0xFF6366F1).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(isMessage ? 'Mensaje' : 'Nuevo', style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: isMessage ? const Color(0xFF6366F1) : const Color(0xFFF59E0B))),
                ),
                const SizedBox(width: 6),
                Text(_timeAgo(item.timestamp), style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
              ]),
              const SizedBox(height: 4),
              Text(item.title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.subtitle, style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.45)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          Icon(Iconsax.arrow_right, color: Colors.white.withValues(alpha: 0.3), size: 20),
        ]),
      ),
    );
  }

  IconData _iconForEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Iconsax.clock;
      case 'confirmado':
        return Iconsax.tick_circle;
      case 'entregado':
        return Iconsax.truck;
      case 'cancelado':
        return Iconsax.close_circle;
      default:
        return Iconsax.receipt_2;
    }
  }

  Color _colorForEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppTheme.warning;
      case 'confirmado':
        return AppTheme.info;
      case 'entregado':
        return AppTheme.green;
      case 'cancelado':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }
}

// ─── Modelos internos ──────────────────────────────────────────────────────────
enum _NotifType { order, message }

class _NotifItem {
  final _NotifType type;
  final String title;
  final String subtitle;
  final Timestamp? timestamp;
  final String docId;
  final String estado;

  const _NotifItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.docId,
    required this.estado,
  });
}
