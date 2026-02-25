import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final bool isVendedor;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.isVendedor,
  });

  @override
  Widget build(BuildContext context) {
    final status = orderData['estado'] ?? 'pendiente';
    final producto = orderData['productoNombre'] ?? 'Producto';
    final cantidad = orderData['cantidad'] ?? 0;
    final unidad = orderData['unidad'] ?? 'c/u';
    final precioUnit = orderData['precioUnitario'] ?? 0;
    final total = orderData['precioTotal'] ?? 0;
    final comprador = orderData['compradorNombre'] ?? 'Comprador';
    final vendedorName = orderData['vendedorNombre'] ?? 'Vendedor';
    final style = AppTheme.getCategoryStyle(orderData['productoCategoria']);
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(gradient: AppTheme.orangeGradient),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppTheme.radiusS,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Detalle del pedido',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Status card
                    _statusCard(status),
                    const SizedBox(height: 16),

                    // Product info
                    _infoSection('Producto', [
                      _infoRow(Icons.inventory_2_outlined, 'Producto', producto),
                      _infoRow(Icons.category_outlined, 'Categoría',
                          orderData['productoCategoria'] ?? 'N/A'),
                      _infoRow(Icons.layers_outlined, 'Cantidad',
                          '$cantidad $unidad'),
                      _infoRow(Icons.attach_money_rounded, 'Precio unitario',
                          '\$$precioUnit'),
                      _infoRow(Icons.receipt_rounded, 'Total', '\$$total',
                          highlight: true),
                    ]),
                    const SizedBox(height: 16),

                    // People info
                    _infoSection('Participantes', [
                      _infoRow(Icons.shopping_bag_outlined, 'Comprador', comprador),
                      _infoRow(
                          Icons.storefront_outlined, 'Vendedor', vendedorName),
                    ]),
                    const SizedBox(height: 24),

                    // Actions for vendor
                    if (isVendedor && status == 'pendiente') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await firestoreService.updateOrderStatus(
                                orderId, 'confirmado');
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 20),
                          label: Text('Confirmar pedido',
                              style: AppTheme.buttonText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.radiusM),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (isVendedor && status == 'confirmado')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await firestoreService.updateOrderStatus(
                                orderId, 'entregado');
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.local_shipping_rounded,
                              color: Colors.white, size: 20),
                          label: Text('Marcar como entregado',
                              style: AppTheme.buttonText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.info,
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.radiusM),
                          ),
                        ),
                      ),
                    if (status == 'pendiente')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await firestoreService.updateOrderStatus(
                                orderId, 'cancelado');
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.cancel_outlined,
                              color: AppTheme.error, size: 20),
                          label: Text('Cancelar pedido',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppTheme.error, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.radiusM),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(String status) {
    Color color;
    IconData icon;
    String label;
    String desc;

    switch (status) {
      case 'pendiente':
        color = AppTheme.warning;
        icon = Icons.schedule_rounded;
        label = 'Pendiente';
        desc = 'Esperando confirmación del comerciante';
        break;
      case 'confirmado':
        color = AppTheme.info;
        icon = Icons.check_circle_outline_rounded;
        label = 'Confirmado';
        desc = 'El comerciante ha confirmado tu pedido';
        break;
      case 'entregado':
        color = AppTheme.success;
        icon = Icons.local_shipping_rounded;
        label = 'Entregado';
        desc = 'El pedido ha sido entregado exitosamente';
        break;
      case 'cancelado':
        color = AppTheme.error;
        icon = Icons.cancel_outlined;
        label = 'Cancelado';
        desc = 'Este pedido fue cancelado';
        break;
      default:
        color = AppTheme.textMuted;
        icon = Icons.help_outline;
        label = status;
        desc = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppTheme.radiusL,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(desc,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusL,
        boxShadow: [AppTheme.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5)),
          ),
          ...items,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.caption),
          const Spacer(),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: highlight ? 16 : 13,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                  color: highlight ? AppTheme.orange : AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
