import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'package:iconsax/iconsax.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _fs = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Map<String, int> _summary = {};
  bool _loadingSummary = true;
  int _filtro = 0; // 0=todos, 1=ok, 2=bajo, 3=critico, 4=agotado
  String _catFiltro = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    final s = await _fs.getInventorySummary(_uid);
    if (mounted) setState(() { _summary = s; _loadingSummary = false; });
  }

  // Determinar nivel de stock
  static int _stockLevel(int stock) {
    if (stock == 0) return 4; // agotado
    if (stock <= 3) return 3; // critico
    if (stock <= 10) return 2; // bajo
    return 1; // ok
  }

  static Color _levelColor(int level) {
    switch (level) {
      case 1: return const Color(0xFF16A34A); // verde
      case 2: return const Color(0xFFFBBF24); // amarillo
      case 3: return const Color(0xFF1C3320); // naranja
      case 4: return const Color(0xFFEF4444); // rojo
      default: return const Color(0xFF94A3B8);
    }
  }

  static IconData _levelIcon(int level) {
    switch (level) {
      case 1: return Iconsax.tick_circle;
      case 2: return Iconsax.warning_2;
      case 3: return Iconsax.warning_2;
      case 4: return Iconsax.close_circle;
      default: return Iconsax.info_circle;
    }
  }

  static String _levelLabel(int level) {
    switch (level) {
      case 1: return 'OK';
      case 2: return 'Bajo';
      case 3: return 'Crítico';
      case 4: return 'Agotado';
      default: return '';
    }
  }

  bool _passesFilter(Map<String, dynamic> data) {
    final activo = data['activo'] as bool? ?? true;
    if (!activo) return false;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final level = _stockLevel(stock);
    if (_filtro != 0 && level != _filtro) return false;
    if (_catFiltro != 'Todas') {
      final cat = data['categoria'] as String? ?? '';
      if (cat != _catFiltro) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadSummary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildSummaryCards()),
            SliverToBoxAdapter(child: _buildFilters()),
            _buildProductList(),
            SliverToBoxAdapter(
                child: SizedBox(
                    height: 32 + MediaQuery.of(context).padding.bottom)),
          ])));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HERO HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHero() {
    return Container(
      color: const Color(0xFF0A0F0A),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _circleBtn(Iconsax.arrow_left, () => Navigator.pop(context)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Inventario',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 26, fontWeight: FontWeight.w400,
                            color: AppTheme.primary))),
                  _circleBtn(Iconsax.refresh, _loadSummary),
                ]),
              const SizedBox(height: 4),
              Text('Control de stock en tiempo real',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
            ]))));
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.primary, size: 20)));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SUMMARY CARDS (semáforo)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSummaryCards() {
    if (_loadingSummary) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }

    final items = [
      ('Todos', _summary['total'] ?? 0, const Color(0xFF6366F1), Iconsax.element_3),
      ('OK', _summary['ok'] ?? 0, const Color(0xFF16A34A), Iconsax.tick_circle),
      ('Bajo', _summary['bajo'] ?? 0, const Color(0xFFFBBF24), Iconsax.warning_2),
      ('Crítico', _summary['critico'] ?? 0, const Color(0xFF1C3320), Iconsax.warning_2),
      ('Agotado', _summary['agotado'] ?? 0, const Color(0xFFEF4444), Iconsax.close_circle),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final isSelected = _filtro == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filtro = i == _filtro ? 0 : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < items.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? item.$3.withValues(alpha: 0.14) : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? item.$3 : AppTheme.border,
                    width: 1.5),
                  boxShadow: isSelected ? [
                    BoxShadow(color: item.$3.withValues(alpha: 0.30),
                        blurRadius: 14, spreadRadius: 0.5, offset: const Offset(0, 4)),
                  ] : null),
                child: Column(
                  children: [
                    Icon(item.$4, color: item.$3, size: 18),
                    const SizedBox(height: 4),
                    Text('${item.$2}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: item.$3)),
                    Text(item.$1,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.45))),
                  ]))));
        }).toList()));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FILTROS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFilters() {
    final categorias = ['Todas', 'Frutas', 'Verduras', 'Tubérculos', 'Granos',
        'Lácteos', 'Carnes', 'Productos del mar', 'Otros'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categorias.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = categorias[i];
            final sel = _catFiltro == cat;
            return GestureDetector(
              onTap: () => setState(() => _catFiltro = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: sel ? null : Border.all(color: const Color(0xFFE2E8F0))),
                alignment: Alignment.center,
                child: Text(cat,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppTheme.textMuted))));
          })));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRODUCT LIST
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getMyProducts(_uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
        }

        final docs = snap.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _passesFilter(data);
        }).toList();

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.box,
                      color: Colors.white.withValues(alpha: 0.45).withValues(alpha: 0.3), size: 56),
                  const SizedBox(height: 12),
                  Text('Sin productos en este filtro',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, color: Colors.white.withValues(alpha: 0.45))),
                ])));
        }

        // Ordenar: agotados primero, luego críticos, luego bajo, luego ok
        filtered.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final sa = (da['stock'] as num?)?.toInt() ?? 0;
          final sb = (db['stock'] as num?)?.toInt() ?? 0;
          return sa.compareTo(sb);
        });

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildProductTile(filtered[i]),
              childCount: filtered.length)));
      });
  }

  Widget _buildProductTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] as String? ?? 'Producto';
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final categoria = data['categoria'] as String? ?? '';
    final unidad = data['unidad'] as String? ?? 'unidad';
    final imgUrl = data['imagenUrl'] as String? ?? '';
    final level = _stockLevel(stock);
    final color = _levelColor(level);

    return GestureDetector(
      onTap: () => _showStockBottomSheet(doc.id, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131C13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: level >= 3 ? color.withValues(alpha: 0.4) : AppTheme.border,
            width: level >= 3 ? 1.5 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8, offset: const Offset(0, 2)),
          ]),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imgUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imgUrl, width: 56, height: 56, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 56, height: 56,
                        color: const Color(0xFF131C13),
                        child: const Icon(Iconsax.gallery, color: Color(0xFFCBD5E1))),
                      errorWidget: (_, __, ___) => Container(
                        width: 56, height: 56,
                        color: const Color(0xFF131C13),
                        child: const Icon(Icons.broken_image, color: Color(0xFFCBD5E1))))
                  : Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF131C13),
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Iconsax.box,
                          color: Color(0xFFCBD5E1), size: 24))),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (categoria.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131C13),
                            borderRadius: BorderRadius.circular(6)),
                          child: Text(categoria,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.45)))),
                        const SizedBox(width: 6),
                      ],
                      Text(unidad,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: Colors.white.withValues(alpha: 0.45))),
                    ]),
                ])),

            // Stock badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25))),
              child: Column(
                children: [
                  Icon(_levelIcon(level), color: color, size: 16),
                  const SizedBox(height: 2),
                  Text('$stock',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                  Text(_levelLabel(level),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 8, fontWeight: FontWeight.w600, color: color)),
                ])),

            const SizedBox(width: 8),
            Icon(Iconsax.arrow_right, color: Colors.white.withValues(alpha: 0.45).withValues(alpha: 0.4)),
          ])));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET — Ajustar stock + historial
  // ═══════════════════════════════════════════════════════════════════
  void _showStockBottomSheet(String productId, Map<String, dynamic> data) {
    final nombre = data['nombre'] as String? ?? 'Producto';
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    bool isAdding = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            decoration: const BoxDecoration(
              color: const Color(0xFF131C13),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2))),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18, fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Stock actual: ',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _levelColor(_stockLevel(stock)).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: Text('$stock',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15, fontWeight: FontWeight.w800,
                                          color: _levelColor(_stockLevel(stock))))),
                              ]),
                          ])),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Iconsax.close_circle)),
                    ])),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Ajustar stock
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ajustar stock',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      // Toggle entrada/salida
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setBS(() => isAdding = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isAdding
                                      ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                      : const Color(0xFF131C13),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isAdding
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFE2E8F0))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.add_circle,
                                        color: isAdding
                                            ? const Color(0xFF16A34A)
                                            : AppTheme.textMuted,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Text('Entrada',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, fontWeight: FontWeight.w700,
                                            color: isAdding
                                                ? const Color(0xFF16A34A)
                                                : AppTheme.textMuted)),
                                  ])))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setBS(() => isAdding = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isAdding
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                      : const Color(0xFF131C13),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: !isAdding
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFE2E8F0))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.minus_cirlce,
                                        color: !isAdding
                                            ? const Color(0xFFEF4444)
                                            : AppTheme.textMuted,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Text('Salida',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, fontWeight: FontWeight.w700,
                                            color: !isAdding
                                                ? const Color(0xFFEF4444)
                                                : AppTheme.textMuted)),
                                  ])))),
                        ]),
                      const SizedBox(height: 12),
                      // Cantidad + motivo
                      Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: cantidadCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                hintText: 'Cant.',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, color: Colors.white.withValues(alpha: 0.45)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppTheme.primary, width: 2))))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: motivoCtrl,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Motivo (ej: restock, merma)',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppTheme.primary, width: 2))))),
                        ]),
                      const SizedBox(height: 12),
                      // Botón confirmar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _doAdjust(
                            ctx, productId, cantidadCtrl.text,
                            motivoCtrl.text, isAdding),
                          icon: Icon(isAdding ? Iconsax.add : Iconsax.minus_cirlce,
                              size: 18),
                          label: Text(isAdding ? 'Agregar stock' : 'Retirar stock',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdding
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0))),
                    ])),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Historial de movimientos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Historial de movimientos',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const Spacer(),
                      Icon(Iconsax.clock, color: Colors.white.withValues(alpha: 0.45), size: 18),
                    ])),
                const SizedBox(height: 8),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fs.getStockMovements(productId),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(color: AppTheme.primary));
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.clock,
                                  color: Colors.white.withValues(alpha: 0.45).withValues(alpha: 0.3), size: 36),
                              const SizedBox(height: 8),
                              Text('Sin movimientos registrados',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                            ]));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          final tipo = d['tipo'] as String? ?? 'entrada';
                          final cantidad = (d['cantidad'] as num?)?.toInt() ?? 0;
                          final motivo = d['motivo'] as String? ?? '';
                          final antes = (d['stockAnterior'] as num?)?.toInt() ?? 0;
                          final despues = (d['stockNuevo'] as num?)?.toInt() ?? 0;
                          final ts = d['timestamp'] as Timestamp?;
                          final fecha = ts?.toDate();
                          final isEntrada = tipo == 'entrada';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: (isEntrada
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFEF4444))
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                  child: Icon(
                                    isEntrada
                                        ? Iconsax.arrow_down
                                        : Iconsax.arrow_up,
                                    color: isEntrada
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFEF4444),
                                    size: 16)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${isEntrada ? '+' : '-'}$cantidad — $motivo',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, fontWeight: FontWeight.w600,
                                            color: Colors.white),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$antes → $despues${fecha != null ? '  •  ${_fmtDate(fecha)}' : ''}',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
                                    ])),
                              ]));
                        });
                    })),
              ]));
        }));
  }

  Future<void> _doAdjust(BuildContext ctx, String productId,
      String cantStr, String motivo, bool isAdding) async {
    final cant = int.tryParse(cantStr);
    if (cant == null || cant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida')));
      return;
    }
    if (motivo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un motivo')));
      return;
    }

    try {
      await _fs.adjustStock(
        productId: productId,
        delta: isAdding ? cant : -cant,
        motivo: motivo.trim(),
        userId: _uid);
      if (mounted) {
        Navigator.pop(ctx);
        _loadSummary();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdding
                ? '+$cant unidades agregadas'
                : '-$cant unidades retiradas'),
            backgroundColor: isAdding
                ? const Color(0xFF16A34A)
                : const Color(0xFFEF4444)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${d.day}/${d.month}/${d.year}';
  }
}
