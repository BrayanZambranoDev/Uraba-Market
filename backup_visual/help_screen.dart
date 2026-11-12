import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<_FaqItem> _faqs = const [
    _FaqItem(
      pregunta: '¿Cómo publico un producto?',
      respuesta:
          'Inicia sesión como Comerciante, ve a la pantalla principal y toca el botón "Publicar". Completa el formulario con el nombre, categoría, precio, unidad y stock de tu producto. Tu producto quedará visible en el marketplace de inmediato.',
      icon: Iconsax.export_3),
    _FaqItem(
      pregunta: '¿Cómo realizo un pedido?',
      respuesta:
          'Busca el producto que deseas en la pantalla principal o en la sección "Buscar". Toca el producto para ver sus detalles, selecciona la cantidad con los botones + y –, y toca "Pedir". El comerciante recibirá tu pedido en el acto.',
      icon: Iconsax.bag),
    _FaqItem(
      pregunta: '¿Cómo contacto a un vendedor?',
      respuesta:
          'Desde la pantalla de detalle de cualquier producto, toca el botón "Contactar" que aparece junto al nombre del vendedor. Esto abrirá un chat directo en tiempo real.',
      icon: Iconsax.message),
    _FaqItem(
      pregunta: '¿Cómo veo el estado de mis pedidos?',
      respuesta:
          'En la barra inferior, toca el ícono de pedidos. Allí verás todos tus pedidos organizados por estado: Pendiente, Confirmado, Entregado o Cancelado. Los comerciantes pueden confirmar y marcar como entregado desde esa misma pantalla.',
      icon: Iconsax.receipt_2),
    _FaqItem(
      pregunta: '¿Cómo cambio mi rol entre Comprador y Comerciante?',
      respuesta:
          'Ve a tu perfil (ícono de persona en la barra inferior), toca "Editar perfil" y cambia el rol desde el selector. Guarda los cambios y el rol se actualizará de inmediato.',
      icon: Iconsax.user_edit),
    _FaqItem(
      pregunta: '¿Qué es el Asistente IA?',
      respuesta:
          'El Asistente IA analiza automáticamente los datos del marketplace: cuántos productos hay por categoría, estadísticas de precios (mínimo, promedio, máximo) y te sugiere oportunidades de negocio basadas en la demanda y oferta actual.',
      icon: Iconsax.cpu),
    _FaqItem(
      pregunta: '¿Mis datos están protegidos?',
      respuesta:
          'Sí. Urabá Market usa Firebase Authentication para gestionar tus credenciales de forma segura y Firestore para almacenar tu información. La plataforma cumple con la Ley 527 de 1999 y la Ley 1581 de 2012 (Ley de Habeas Data).',
      icon: Iconsax.shield),
    _FaqItem(
      pregunta: '¿Cómo recupero mi contraseña?',
      respuesta:
          'En la pantalla de inicio de sesión, escribe tu correo electrónico y toca "¿Olvidaste tu contraseña?". Recibirás un correo con las instrucciones para restablecerla.',
      icon: Iconsax.lock),
    _FaqItem(
      pregunta: '¿Qué hago si un pedido no llega?',
      respuesta:
          'Contacta directamente al comerciante usando el chat integrado en la plataforma. Si no obtienes respuesta, puedes cancelar el pedido desde la pantalla de detalle del pedido mientras esté en estado "Pendiente".',
      icon: Iconsax.info_circle),
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  Text('Preguntas frecuentes', style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 12),
                  ..._faqs.asMap().entries.map(
                        (e) => _buildFaqTile(e.key, e.value)),
                  const SizedBox(height: 24),
                  _buildContactCard(),
                ])),
          ])));
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: Color(0xFF0A0F0A)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle),
              child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20))),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ayuda y Soporte',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Resolvemos tus dudas',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            ]),
        ]));
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: AppTheme.radiusL,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25))),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: AppTheme.radiusM),
            child: Icon(Iconsax.tree, color: AppTheme.primary, size: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Urabá Market v1.0',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Plataforma Digital para Comerciantes y Emprendedores de Urabá',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
              ])),
        ]));
  }

  Widget _buildFaqTile(int index, _FaqItem faq) {
    final isExpanded = _expandedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131C13),
        borderRadius: AppTheme.radiusM,
        border: Border.all(
          color: isExpanded
              ? AppTheme.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
          width: isExpanded ? 1.5 : 1)),
      child: ClipRRect(
        borderRadius: AppTheme.radiusM,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                setState(() => _expandedIndex = isExpanded ? null : index),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : AppTheme.bg,
                          borderRadius: AppTheme.radiusS),
                        child: Icon(faq.icon,
                            size: 18,
                            color: isExpanded
                                ? AppTheme.primary
                                : Colors.white.withValues(alpha: 0.45))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(faq.pregunta,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isExpanded
                                    ? AppTheme.primary
                                    : Colors.white))),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Iconsax.arrow_down,
                            color: isExpanded
                                ? AppTheme.primary
                                : Colors.white.withValues(alpha: 0.45),
                            size: 20)),
                    ])),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      children: [
                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                        const SizedBox(height: 12),
                        Text(faq.respuesta,
                            style: AppTheme.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.6), height: 1.5)),
                      ])),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200)),
              ])))));
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: AppTheme.radiusL,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.headphone,
                  color: AppTheme.green, size: 20),
              const SizedBox(width: 8),
              Text('¿No encontraste tu respuesta?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ]),
          const SizedBox(height: 6),
          Text(
              'Contáctanos directamente desde el chat de la plataforma o escríbenos a través del perfil de un administrador.',
              style: AppTheme.body
                  .copyWith(color: Colors.white.withValues(alpha: 0.6), height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.radiusS,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.book, color: Colors.white.withValues(alpha: 0.45), size: 15),
                const SizedBox(width: 6),
                Text('Universidad Católica Luis Amigó · 2025',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500)),
              ])),
        ]));
  }
}

class _FaqItem {
  final String pregunta;
  final String respuesta;
  final IconData icon;

  const _FaqItem({
    required this.pregunta,
    required this.respuesta,
    required this.icon,
  });
}
