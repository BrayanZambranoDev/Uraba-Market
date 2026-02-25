import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver tus mensajes'));
    }

    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Mensajes', style: AppTheme.heading2),
                ],
              ),
            ),

            // Lista de conversaciones
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getConversations(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.orange));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No tienes conversaciones',
                              style: AppTheme.bodyMuted),
                          const SizedBox(height: 4),
                          Text(
                              'Contacta a un comerciante desde un producto',
                              style: AppTheme.caption,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      return _buildConversationTile(
                          context, docs[i].id, data, user.uid);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, String convId,
      Map<String, dynamic> data, String currentUserId) {
    final participantes =
        data['participantes'] as Map<String, dynamic>? ?? {};
    final participantIds =
        List<String>.from(data['participantIds'] ?? []);

    // Obtener el otro participante
    final otherUserId =
        participantIds.firstWhere((id) => id != currentUserId,
            orElse: () => '');
    final otherUserName =
        participantes[otherUserId]?.toString() ?? 'Usuario';
    final currentUserName =
        participantes[currentUserId]?.toString() ?? 'Yo';

    final ultimoMensaje = data['ultimoMensaje'] ?? '';
    final ultimoTimestamp = data['ultimoTimestamp'] as Timestamp?;
    final horaStr = ultimoTimestamp != null
        ? '${ultimoTimestamp.toDate().hour}:${ultimoTimestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    final isUnread =
        data['ultimoSenderId'] != null &&
        data['ultimoSenderId'] != currentUserId;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            currentUserName: currentUserName,
            conversationId: convId,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: [AppTheme.shadowSmall],
          border: isUnread
              ? Border.all(color: AppTheme.orange.withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  otherUserName.isNotEmpty
                      ? otherUserName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.orange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUserName,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight:
                              isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    ultimoMensaje,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isUnread
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(horaStr, style: AppTheme.caption),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
