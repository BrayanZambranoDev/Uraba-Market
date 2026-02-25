import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  String _userRole = 'Comprador';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRole();
  }

  void _loadRole() async {
    if (_user == null) return;
    final data = await _firestoreService.getUserData(_user!.uid);
    if (data != null && mounted) {
      setState(() => _userRole = data['rol'] ?? 'Comprador');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pendiente':
        return AppTheme.warning;
      case 'confirmado':
        return AppTheme.info;
      case 'entregado':
        return AppTheme.success;
      case 'cancelado':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'confirmado':
        return Icons.check_circle_outline_rounded;
      case 'entregado':
        return Icons.local_shipping_rounded;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmado':
        return 'Confirmado';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mis Pedidos', style: AppTheme.heading2),
                const SizedBox(height: 4),
                Text(
                    _userRole == 'Comerciante'
                        ? 'Gestiona tus pedidos recibidos y realizados'
                        : 'Revisa el estado de tus pedidos',
                    style: AppTheme.bodyMuted),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: AppTheme.radiusM,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: AppTheme.radiusM,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500),
              dividerHeight: 0,
              tabs: [
                Tab(
                    text: _userRole == 'Comerciante'
                        ? 'Recibidos'
                        : 'Mis compras'),
                Tab(
                    text: _userRole == 'Comerciante'
                        ? 'Mis compras'
                        : 'Enviados'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(asVendedor: _userRole == 'Comerciante'),
                _buildOrderList(asVendedor: _userRole != 'Comerciante'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList({required bool asVendedor}) {
    if (_user == null) {
      return const Center(child: Text('Inicia sesión para ver tus pedidos'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMyOrders(_user!.uid,
          asVendedor: asVendedor),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('Error al cargar pedidos', style: AppTheme.bodyMuted),
                const SizedBox(height: 4),
                Text('Verifica tu conexión', style: AppTheme.caption),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No tienes pedidos aún', style: AppTheme.bodyMuted),
                const SizedBox(height: 4),
                Text(
                    asVendedor
                        ? 'Los pedidos de tus clientes aparecerán aquí'
                        : 'Explora productos y realiza tu primer pedido',
                    style: AppTheme.caption,
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildOrderCard(docs[i].id, data, asVendedor);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
      String orderId, Map<String, dynamic> data, bool asVendedor) {
    final status = data['estado'] ?? 'pendiente';
    final statusColor = _statusColor(status);
    final producto = data['productoNombre'] ?? 'Producto';
    final cantidad = data['cantidad'] ?? 0;
    final unidad = data['unidad'] ?? 'c/u';
    final total = data['precioTotal'] ?? 0;
    final otherName = asVendedor
        ? data['compradorNombre'] ?? 'Comprador'
        : data['vendedorNombre'] ?? 'Vendedor';
    final style = AppTheme.getCategoryStyle(data['productoCategoria']);
    final fecha = data['fechaCreacion'] as Timestamp?;
    final fechaStr = fecha != null
        ? '${fecha.toDate().day}/${fecha.toDate().month}/${fecha.toDate().year}'
        : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: orderId,
            orderData: data,
            isVendedor: asVendedor,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: [AppTheme.shadowSmall],
        ),
        child: Row(
          children: [
            // Icono categoría
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: style['color'] as Color,
                borderRadius: AppTheme.radiusM,
              ),
              child: Icon(style['icon'] as IconData,
                  color: style['accent'] as Color, size: 22),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$cantidad $unidad • $otherName',
                      style: AppTheme.caption),
                  if (fechaStr.isNotEmpty)
                    Text(fechaStr, style: AppTheme.caption),
                ],
              ),
            ),

            // Status + precio
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status),
                          size: 12, color: statusColor),
                      const SizedBox(width: 3),
                      Text(_statusLabel(status),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('\$${total.toString()}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
