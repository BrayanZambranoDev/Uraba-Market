import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'order_detail_screen.dart';
import 'utils/shimmer_box.dart';
import 'package:iconsax/iconsax.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  String _userRole = 'Comprador';
  String? _statusFilter;
  // IDs de pedidos con acción en curso (evita doble tap)
  final Set<String> _actingOrders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRole();
  }

  // Acción rápida con confirmación
  Future<void> _quickAction(
      String orderId, String newStatus, String label) async {
    if (_actingOrders.contains(orderId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        title: Text('¿$label este pedido?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          newStatus == 'confirmado'
              ? 'El comprador será notificado que aceptaste el pedido.'
              : newStatus == 'en_camino'
                  ? 'El comprador será notificado que su pedido está en camino.'
                  : 'Marca el pedido como entregado al comprador.',
          style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'confirmado'
                  ? AppTheme.success
                  : AppTheme.info,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusFull),
              elevation: 0,
            ),
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actingOrders.add(orderId));
    try {
      await _firestoreService.updateOrderStatus(orderId, newStatus);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo actualizar el pedido',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
      ));
    } finally {
      if (mounted) setState(() => _actingOrders.remove(orderId));
    }
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
      case 'en_camino':
        return const Color(0xFF7C3AED);
      case 'entregado':
        return AppTheme.success;
      case 'cancelado':
        return AppTheme.error;
      case 'devolucion_solicitada':
        return const Color(0xFF1C3320);
      case 'devolucion_aceptada':
        return const Color(0xFF16A34A);
      case 'devolucion_rechazada':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pendiente':
        return Iconsax.clock;
      case 'confirmado':
        return Iconsax.tick_circle;
      case 'en_camino':
        return Iconsax.truck;
      case 'entregado':
        return Iconsax.location_tick;
      case 'cancelado':
        return Iconsax.close_circle;
      case 'devolucion_solicitada':
        return Iconsax.undo;
      case 'devolucion_aceptada':
        return Iconsax.tick_circle;
      case 'devolucion_rechazada':
        return Iconsax.clock;
      default:
        return Iconsax.info_circle;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmado':
        return 'Confirmado';
      case 'en_camino':
        return 'En camino';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      case 'devolucion_solicitada':
        return 'Devolución';
      case 'devolucion_aceptada':
        return 'Dev. aceptada';
      case 'devolucion_rechazada':
        return 'Dev. rechazada';
      default:
        return status;
    }
  }

  Widget _statusChip(String? value, String label, Color color) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: AppTheme.radiusFull,
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0F0A),
      child: Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          color: const Color(0xFF0A0F0A),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                GestureDetector(
                  onTap: widget.onBack ?? () => Navigator.maybePop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.arrow_left,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mis Pedidos 🌿', style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(
                    (_userRole == 'Comerciante' || _userRole == 'Productor')
                        ? 'Gestiona tus pedidos recibidos y realizados'
                        : 'Revisa el estado de tus pedidos',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                ])),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.refresh, color: Colors.white.withValues(alpha: 0.7), size: 20),
                ),
              ]),
            ),
          ),
        ),

          // Tabs
          Container(
            color: const Color(0xFF0A0F0A),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                dividerHeight: 0,
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Tab(text: (_userRole == 'Comerciante' || _userRole == 'Productor') ? 'Recibidos' : 'Mis compras'),
                  Tab(text: (_userRole == 'Comerciante' || _userRole == 'Productor') ? 'Mis compras' : 'Enviados'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Chips de estado
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _statusChip(null, 'Todos', AppTheme.textMuted),
                _statusChip('pendiente', 'Pendiente', AppTheme.warning),
                _statusChip('confirmado', 'Confirmado', AppTheme.info),
                _statusChip('en_camino', 'En camino', const Color(0xFF7C3AED)),
                _statusChip('entregado', 'Entregado', AppTheme.green),
                _statusChip('cancelado', 'Cancelado', AppTheme.error),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(asVendedor: _userRole == 'Comerciante' || _userRole == 'Productor'),
                _buildOrderList(asVendedor: !(_userRole == 'Comerciante' || _userRole == 'Productor')),
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
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, __) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131C13),
                borderRadius: AppTheme.radiusL,
                boxShadow: AppTheme.shadowSm,
              ),
              child: Row(children: [
                ShimmerBox(
                    width: 48,
                    height: 48,
                    borderRadius: AppTheme.radiusM),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 13,
                          borderRadius: BorderRadius.circular(6)),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 120, height: 10,
                          borderRadius: BorderRadius.circular(5)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerBox(width: 60, height: 20,
                        borderRadius: BorderRadius.circular(10)),
                    const SizedBox(height: 6),
                    ShimmerBox(width: 44, height: 13,
                        borderRadius: BorderRadius.circular(5)),
                  ],
                ),
              ]),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.warning_2,
                    size: 48, color: AppTheme.textDisabled),
                const SizedBox(height: 8),
                Text('Error al cargar pedidos', style: AppTheme.bodyMuted),
                const SizedBox(height: 4),
                Text('Verifica tu conexión', style: AppTheme.caption),
              ],
            ),
          );
        }

        var docs = snapshot.data?.docs ?? [];

        // Filtro por estado
        if (_statusFilter != null) {
          docs = docs
              .where((d) =>
                  (d.data() as Map<String, dynamic>)['estado'] == _statusFilter)
              .toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.receipt_2,
                        size: 40, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    asVendedor ? 'Aún no tienes pedidos' : 'Aún no has hecho pedidos',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    asVendedor
                        ? 'Cuando un comprador solicite tus productos, aparecerán aquí.'
                        : 'Encuentra productos locales del Urabá y realiza tu primer pedido.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                  if (!asVendedor) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Iconsax.search_normal, size: 18),
                        label: Text('Explorar productos', style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 300)),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _buildOrderCard(docs[i].id, data, asVendedor);
            },
          ),
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

    final isActing = _actingOrders.contains(orderId);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(OrderDetailScreen(
          orderId: orderId,
          orderData: data,
          isVendedor: asVendedor,
        )),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusL,
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: AppTheme.radiusFull,
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

            // ── Botones rápidos para el comerciante ─────────────
            if (asVendedor &&
                (status == 'pendiente' || status == 'confirmado' ||
                    status == 'en_camino')) ...[
              const SizedBox(height: 10),
              isActing
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.orange),
                      ),
                    )
                  : Row(
                      children: [
                        if (status == 'pendiente') ...[
                          Expanded(
                            child: _quickChip(
                              label: 'Confirmar',
                              icon: Iconsax.check,
                              color: AppTheme.success,
                              onTap: () =>
                                  _quickAction(orderId, 'confirmado', 'Confirmar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (status == 'confirmado') ...[
                          Expanded(
                            child: _quickChip(
                              label: 'En camino',
                              icon: Iconsax.truck,
                              color: const Color(0xFF7C3AED),
                              onTap: () =>
                                  _quickAction(orderId, 'en_camino', 'Marcar en camino'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (status == 'en_camino') ...[
                          Expanded(
                            child: _quickChip(
                              label: 'Entregado',
                              icon: Iconsax.location_tick,
                              color: AppTheme.success,
                              onTap: () =>
                                  _quickAction(orderId, 'entregado', 'Marcar entregado'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: _quickChip(
                            label: 'Ver detalle',
                            icon: Iconsax.export_3,
                            color: AppTheme.textMuted,
                            onTap: () => Navigator.push(
                              context,
                              AppTheme.pageRoute(OrderDetailScreen(
                                orderId: orderId,
                                orderData: data,
                                isVendedor: true,
                              )),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppTheme.radiusFull,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
