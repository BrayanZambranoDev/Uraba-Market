import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'publicar_producto_screen.dart';
import 'utils/shimmer_box.dart';
import 'package:iconsax/iconsax.dart';

class MisProductosScreen extends StatefulWidget {
  const MisProductosScreen({super.key});

  @override
  State<MisProductosScreen> createState() => _MisProductosScreenState();
}

class _MisProductosScreenState extends State<MisProductosScreen> {
  final FirestoreService _service = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  String _searchQuery = '';
  String _filterStatus = 'todos'; // 'todos' | 'activos' | 'inactivos'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Eliminar con confirmación ──────────────────────────────────────
  Future<void> _confirmDelete(String productId, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        title: Text('¿Eliminar producto?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('Se eliminará "$nombre" permanentemente.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusS)),
            child: Text('Eliminar',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700))),
        ]));

    if (ok != true || !mounted) return;

    try {
      await _service.deleteProduct(productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Producto eliminado',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al eliminar el producto',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS)));
    }
  }

  // ── Activar / Desactivar ──────────────────────────────────────────
  Future<void> _toggle(String productId, bool currentActive) async {
    try {
      await _service.toggleProductActive(productId, !currentActive);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo actualizar el estado',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS)));
    }
  }

  // ── Quick edit de stock ───────────────────────────────────────────
  Future<void> _quickEditStock(
      String productId, String nombre, int currentStock) async {
    final ctrl =
        TextEditingController(text: currentStock.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        title: Text('Actualizar stock',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                labelStyle: AppTheme.caption,
                filled: true,
                fillColor: AppTheme.bg,
                border: OutlineInputBorder(
                    borderRadius: AppTheme.radiusM,
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.radiusM,
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.radiusM,
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16))),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusS),
              elevation: 0),
            child: Text('Guardar',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700))),
        ]));

    if (ok != true || !mounted) return;
    final newStock = int.tryParse(ctrl.text.trim()) ?? currentStock;
    if (newStock == currentStock) return;

    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(productId)
          .update({'stock': newStock});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Stock actualizado a $newStock',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al actualizar el stock',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS)));
    }
  }

  // ── Navegar a editar ──────────────────────────────────────────────
  void _goEdit(String productId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      AppTheme.pageRoute(
        PublicarProductoScreen(
          productoId: productId,
          productoData: data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: const Color(0xFF0A0F0A),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppTheme.radiusS),
                      child: Icon(Iconsax.arrow_left,
                          color: AppTheme.primary, size: 20))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mis Productos 🌿',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Gestiona tu catálogo',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                      ])),
                  // Botón agregar nuevo producto (kept below in same Row)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      AppTheme.pageRoute(
                          const PublicarProductoScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: AppTheme.radiusS),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.add,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Nuevo',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ]))),
                ])),
            // ── Barra de búsqueda ──────────────────────────────────
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppTheme.radiusFull,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Buscar en mis productos...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white60),
                    prefixIcon: const Icon(Iconsax.search_normal,
                        color: Colors.white60, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Iconsax.close_circle,
                                color: Colors.white70, size: 16))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10))))),
            // ── Filtros de estado ──────────────────────────────────
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _filterChip('Todos', 'todos'),
                  const SizedBox(width: 8),
                  _filterChip('Activos', 'activos'),
                  const SizedBox(width: 8),
                  _filterChip('Inactivos', 'inactivos'),
                ])),

            // ── Lista de productos ────────────────────────────────
            Expanded(
              child: _uid == null
                  ? const Center(child: Text('Inicia sesión primero'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _service.getMyProducts(_uid!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: 5,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, __) =>
                                const ShimmerListTile());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.warning_2,
                                    size: 48,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text('Error al cargar productos',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
                              ]));
                        }

                        var docs = snapshot.data?.docs ?? [];
                        final total = docs.length;
                        final activos = docs.where((d) =>
                            (d.data() as Map<String, dynamic>)['activo'] ==
                            true).length;

                        // Aplicar filtros
                        if (_filterStatus == 'activos') {
                          docs = docs.where((d) =>
                              (d.data() as Map<String, dynamic>)['activo'] == true).toList();
                        } else if (_filterStatus == 'inactivos') {
                          docs = docs.where((d) =>
                              (d.data() as Map<String, dynamic>)['activo'] != true).toList();
                        }
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          docs = docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                            final cat = (data['categoria'] ?? '').toString().toLowerCase();
                            return nombre.contains(q) || cat.contains(q);
                          }).toList();
                        }

                        if (total == 0) return _emptyState();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner de resumen (totales globales, no filtrados)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppTheme.radiusM),
                              child: Row(
                                children: [
                                  _statChip(Iconsax.box,
                                      '$total producto${total == 1 ? '' : 's'}',
                                      AppTheme.primary),
                                  const SizedBox(width: 12),
                                  _statChip(Iconsax.eye,
                                      '$activos activo${activos == 1 ? '' : 's'}',
                                      AppTheme.success),
                                  const SizedBox(width: 12),
                                  _statChip(
                                      Iconsax.eye_slash,
                                      '${total - activos} inactivo${(total - activos) == 1 ? '' : 's'}',
                                      AppTheme.textMuted),
                                ])),
                            if (docs.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Iconsax.search_status,
                                          size: 48,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      Text('Sin resultados',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
                                    ])))
                            else
                              Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                      16, 16, 16,
                                      16 + MediaQuery.of(context).padding.bottom),
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (ctx, i) {
                                    final data = docs[i].data()
                                        as Map<String, dynamic>;
                                    return _buildProductTile(
                                        docs[i].id, data);
                                  })),
                          ]);
                      })),
          ])));
  }

  Widget _filterChip(String label, String value) {
    final selected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.inputBg,
          borderRadius: AppTheme.radiusFull),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSecondary))));
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ]);
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle),
              child: const Icon(Iconsax.box,
                  size: 40, color: AppTheme.primary)),
            const SizedBox(height: 16),
            Text('Sin productos publicados',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Publica tu primer producto para que\nlos compradores te encuentren.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                AppTheme.pageRoute(
                    const PublicarProductoScreen())),
              icon: const Icon(Iconsax.add,
                  color: Colors.white, size: 18),
              label: Text('Publicar producto',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusM),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12))),
          ])));
  }

  Widget _buildProductTile(String productId, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? 'Producto';
    final precio = (data['precio'] ?? 0).toDouble();
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final unidad = data['unidad'] ?? 'c/u';
    final activo = data['activo'] ?? true;
    final categoria = data['categoria'] ?? 'Otros';
    final vistas = (data['vistas'] as num?)?.toInt() ?? 0;
    final ratingAvg = (data['ratingAvg'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
    final imagenUrl = data['imagenUrl'] as String?;
    final style = AppTheme.getCategoryStyle(categoria);

    return GestureDetector(
      onLongPress: () => _quickEditStock(productId, nombre, stock),
      child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131C13),
        borderRadius: AppTheme.radiusL,
        border: activo
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.08).withValues(alpha: 0.5), width: 1)),
      child: Row(
        children: [
          // ── Miniatura ────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: SizedBox(
              width: 90,
              height: 90,
              child: imagenUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imagenUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: style['color'] as Color,
                        child: Icon(style['icon'] as IconData,
                            color: (style['accent'] as Color)
                                .withValues(alpha: 0.4),
                            size: 32)),
                      errorWidget: (_, __, ___) => Container(
                        color: style['color'] as Color,
                        child: Icon(style['icon'] as IconData,
                            color: style['accent'] as Color, size: 32)))
                  : Container(
                      color: style['color'] as Color,
                      child: Center(
                        child: Icon(style['icon'] as IconData,
                            color: style['accent'] as Color, size: 32))))),

          // ── Info ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + badge estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(nombre,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: activo
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activo
                              ? AppTheme.success.withValues(alpha: 0.15)
                              : AppTheme.textMuted.withValues(alpha: 0.12),
                          borderRadius: AppTheme.radiusFull,
                          border: Border.all(
                            color: activo
                                ? AppTheme.success.withValues(alpha: 0.4)
                                : AppTheme.textMuted.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: activo ? AppTheme.success : AppTheme.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activo ? 'Activo' : 'Inactivo',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: activo
                                    ? AppTheme.success
                                    : AppTheme.textMuted)),
                        ])),
                    ]),
                  const SizedBox(height: 4),
                  Text(
                    '\$${precio.toStringAsFixed(0)} / $unidad',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
                  Row(
                    children: [
                      Text('Stock: $stock $unidad', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
                      if (stock > 0 && stock <= 5) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.15),
                            borderRadius: AppTheme.radiusFull,
                            border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.4))),
                          child: Text('¡Pocas unidades!',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.warning))),
                      ] else if (stock == 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.12),
                            borderRadius: AppTheme.radiusFull,
                            border: Border.all(
                                color: AppTheme.error.withValues(alpha: 0.35))),
                          child: Text('Agotado',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.error))),
                      ],
                    ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Iconsax.eye,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.45)),
                    const SizedBox(width: 3),
                    Text('$vistas',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45)).copyWith(fontSize: 10)),
                    if (ratingCount > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Iconsax.star5,
                          size: 11, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(
                        '${ratingAvg.toStringAsFixed(1)} ($ratingCount)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45)).copyWith(fontSize: 10)),
                    ],
                  ]),
                ]))),

          // ── Acciones ─────────────────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Toggle activo
              GestureDetector(
                onTap: () => _toggle(productId, activo),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: Icon(
                    activo
                        ? Iconsax.eye
                        : Iconsax.eye_slash,
                    size: 20,
                    color: activo ? AppTheme.green : AppTheme.textMuted))),
              // Editar
              GestureDetector(
                onTap: () => _goEdit(productId, data),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Iconsax.edit,
                      size: 20, color: AppTheme.primary))),
              // Eliminar
              GestureDetector(
                onTap: () => _confirmDelete(productId, nombre),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Iconsax.trash,
                      size: 20, color: AppTheme.error))),
            ]),
          const SizedBox(width: 4),
        ])));
  }
}
