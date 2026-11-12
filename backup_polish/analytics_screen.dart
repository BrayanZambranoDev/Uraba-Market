import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'package:iconsax/iconsax.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final _fs = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Map<String, dynamic>? _stats;
  bool _loading = true;
  late TabController _tabCtrl;
  int _touchedPieIndex = -1;

  static const _catColors = [
    Color(0xFF1C3320),
    Color(0xFF16A34A),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFFBBF24),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) setState(() {}); });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _fs.getSellerDetailedStats(_uid);
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  double _safeDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
  int _safeInt(dynamic v) => (v as num?)?.toInt() ?? 0;

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2))),
            Text('Exportar reporte', style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 20),
            _exportOption(
              icon: Iconsax.document,
              color: const Color(0xFFEF4444),
              title: 'Exportar PDF',
              subtitle: 'Reporte visual con tablas formateadas',
              onTap: () { Navigator.pop(context); _exportPDF(); }),
            const SizedBox(height: 12),
            _exportOption(
              icon: Iconsax.chart_2,
              color: const Color(0xFF16A34A),
              title: 'Exportar CSV',
              subtitle: 'Datos tabulares para Excel o Google Sheets',
              onTap: () { Navigator.pop(context); _exportCSV(); }),
            const SizedBox(height: 16),
          ])));
  }

  Widget _exportOption({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
            ])),
          Icon(Iconsax.arrow_right, color: color),
        ])));
  }

  Future<void> _exportCSV() async {
    if (_stats == null) return;
    final s = _stats!;
    final buf = StringBuffer();

    // Header
    buf.writeln('Reporte de Ventas - Urabá Market');
    final now = DateTime.now();
    buf.writeln('Generado: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, "0")}');
    buf.writeln('');

    // KPIs
    buf.writeln('RESUMEN GENERAL');
    buf.writeln('Métrica,Valor');
    buf.writeln('Ganancias totales,${_safeDouble(s["totalVentas"])}');
    buf.writeln('Últimos 30 días,${_safeDouble(s["last30DaysVentas"])}');
    buf.writeln('Total pedidos,${_safeInt(s["totalPedidos"])}');
    buf.writeln('Entregados,${_safeInt(s["entregados"])}');
    buf.writeln('Confirmados,${_safeInt(s["confirmados"])}');
    buf.writeln('Pendientes,${_safeInt(s["pendientes"])}');
    buf.writeln('Cancelados,${_safeInt(s["cancelados"])}');
    buf.writeln('Productos activos,${_safeInt(s["productosActivos"])}');
    final rating = _safeDouble(s['ratingAvg']);
    buf.writeln('Rating promedio,${rating > 0 ? rating.toStringAsFixed(1) : "N/A"}');
    final total = _safeInt(s['totalPedidos']);
    final entregados = _safeInt(s['entregados']);
    buf.writeln('Tasa de entrega,${total > 0 ? "${(entregados / total * 100).toStringAsFixed(1)}%" : "N/A"}');
    buf.writeln('');

    // Top productos
    final top = (s['topProductos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (top.isNotEmpty) {
      buf.writeln('TOP PRODUCTOS');
      buf.writeln('#,Producto,Pedidos');
      for (var i = 0; i < top.length; i++) {
        buf.writeln('${i + 1},${top[i]["nombre"]},${top[i]["pedidos"]}');
      }
      buf.writeln('');
    }

    // Ventas por categoría
    final catVentas = (s['categoriaVentas'] as Map<String, double>?) ?? {};
    if (catVentas.isNotEmpty) {
      final totalCat = catVentas.values.fold(0.0, (a, b) => a + b);
      buf.writeln('VENTAS POR CATEGORÍA');
      buf.writeln('Categoría,Ventas COP,%');
      final sorted = catVentas.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        buf.writeln('${e.key},${e.value.toStringAsFixed(0)},${(e.value / totalCat * 100).toStringAsFixed(1)}%');
      }
      buf.writeln('');
    }

    // Ventas por día
    final ventasDia = (s['ventasPorDia'] as Map<String, double>?) ?? {};
    if (ventasDia.isNotEmpty) {
      buf.writeln('VENTAS POR DÍA (ÚLTIMOS 7 DÍAS)');
      buf.writeln('Día,Ventas COP');
      for (final e in ventasDia.entries) {
        buf.writeln('${e.key},${e.value.toStringAsFixed(0)}');
      }
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reporte_ventas_${now.day}_${now.month}_${now.year}.csv');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Reporte Urabá Market - ${now.day}/${now.month}/${now.year}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _exportPDF() async {
    if (_stats == null) return;
    final s = _stats!;
    final ganancias = _safeDouble(s['totalVentas']);
    final last30 = _safeDouble(s['last30DaysVentas']);
    final pedidos = _safeInt(s['totalPedidos']);
    final entregados = _safeInt(s['entregados']);
    final cancelados = _safeInt(s['cancelados']);
    final pendientes = _safeInt(s['pendientes']);
    final confirmados = _safeInt(s['confirmados']);
    final activos = _safeInt(s['productosActivos']);
    final rating = _safeDouble(s['ratingAvg']);
    final ratingCount = _safeInt(s['ratingCount']);
    final top = (s['topProductos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final catVentas = (s['categoriaVentas'] as Map<String, double>?) ?? {};
    final now = DateTime.now();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          // Título
          pw.Center(
            child: pw.Text('Reporte de Ventas — Urabá Market',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Generado el ${now.day}/${now.month}/${now.year} a las ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
          pw.Divider(thickness: 2, color: PdfColors.orange),
          pw.SizedBox(height: 16),

          // KPIs principales
          pw.Text('Resumen General',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
            cellStyle: const pw.TextStyle(fontSize: 13),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.orange50),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Métrica', 'Valor'],
            data: [
              ['Ganancias totales', '\$${_fmtMoney(ganancias)} COP'],
              ['Últimos 30 días', '\$${_fmtMoney(last30)} COP'],
              ['Total pedidos', '$pedidos'],
              ['Entregados', '$entregados'],
              ['Confirmados', '$confirmados'],
              ['Pendientes', '$pendientes'],
              ['Cancelados', '$cancelados'],
              ['Productos activos', '$activos'],
              ['Rating promedio', rating > 0 ? '${rating.toStringAsFixed(1)} / 5.0 ($ratingCount reseñas)' : 'Sin reseñas'],
              ['Tasa de entrega', pedidos > 0 ? '${(entregados / pedidos * 100).toStringAsFixed(1)}%' : 'N/A'],
              ['Tasa de cancelación', pedidos > 0 ? '${(cancelados / pedidos * 100).toStringAsFixed(1)}%' : 'N/A'],
            ]),
          pw.SizedBox(height: 20),

          // Top productos
          if (top.isNotEmpty) ...[
            pw.Text('Top Productos Más Vendidos',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
              cellStyle: const pw.TextStyle(fontSize: 13),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
              headers: ['#', 'Producto', 'Pedidos'],
              data: top.asMap().entries.map((e) => [
                '${e.key + 1}',
                e.value['nombre'] as String? ?? '',
                '${e.value['pedidos'] ?? 0}',
              ]).toList()),
            pw.SizedBox(height: 20),
          ],

          // (Ventas por categoría se muestra en la página corregida abajo)
        ]));

    // Rehacer la tabla de categorías correctamente
    if (catVentas.isNotEmpty) {
      final totalCat = catVentas.values.fold(0.0, (a, b) => a + b);
      final sortedCat = catVentas.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Reemplazar última página con versión correcta
      pdf.document.pdfPageList.pages.removeLast();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (ctx) => [
            pw.Text('Reporte de Ventas — Urabá Market',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Generado el ${now.day}/${now.month}/${now.year}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
            pw.Divider(thickness: 2, color: PdfColors.orange),
            pw.SizedBox(height: 16),

            pw.Text('Resumen General',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
              cellStyle: const pw.TextStyle(fontSize: 13),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange50),
              headers: ['Métrica', 'Valor'],
              data: [
                ['Ganancias totales', '\$${_fmtMoney(ganancias)} COP'],
                ['Últimos 30 días', '\$${_fmtMoney(last30)} COP'],
                ['Total pedidos', '$pedidos'],
                ['Entregados', '$entregados'],
                ['Confirmados', '$confirmados'],
                ['Pendientes', '$pendientes'],
                ['Cancelados', '$cancelados'],
                ['Productos activos', '$activos'],
                ['Rating', rating > 0 ? '${rating.toStringAsFixed(1)}/5 ($ratingCount)' : 'Sin reseñas'],
                ['Tasa entrega', pedidos > 0 ? '${(entregados / pedidos * 100).toStringAsFixed(1)}%' : 'N/A'],
              ]),
            pw.SizedBox(height: 20),

            if (top.isNotEmpty) ...[
              pw.Text('Top Productos',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                cellStyle: const pw.TextStyle(fontSize: 13),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
                headers: ['#', 'Producto', 'Pedidos'],
                data: top.asMap().entries.map((e) => [
                  '${e.key + 1}',
                  e.value['nombre'] as String? ?? '',
                  '${e.value['pedidos'] ?? 0}',
                ]).toList()),
              pw.SizedBox(height: 20),
            ],

            pw.Text('Ventas por Categoría',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
              cellStyle: const pw.TextStyle(fontSize: 13),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              headers: ['Categoría', 'Ventas (COP)', '%'],
              data: sortedCat.map((e) => [
                e.key,
                '\$${_fmtMoney(e.value)}',
                '${(e.value / totalCat * 100).toStringAsFixed(1)}%',
              ]).toList()),
          ]));
    }

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'Reporte_Ventas_${now.day}_${now.month}_${now.year}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
            else ...[
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey(_tabCtrl.index),
                    child: _buildActiveTab()))),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ])));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HERO HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHero() {
    final ganancias = _safeDouble(_stats?['totalVentas']);
    final last30 = _safeDouble(_stats?['last30DaysVentas']);
    final pedidos = _safeInt(_stats?['totalPedidos']);
    final entregados = _safeInt(_stats?['entregados']);
    final rating = _safeDouble(_stats?['ratingAvg']);
    final activos = _safeInt(_stats?['productosActivos']);

    // Crecimiento simple: si hay ventas totales, mostrar qué % son de los últimos 30 días
    final growthPct = ganancias > 0 ? (last30 / ganancias * 100) : 0.0;

    return Container(
      color: const Color(0xFF0A0F0A),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  _circleBtn(Iconsax.arrow_left, () => Navigator.pop(context)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Panel de Ganancias',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 19, fontWeight: FontWeight.w800,
                            color: AppTheme.primary))),
                  _circleBtn(Iconsax.export_3, _showExportOptions),
                  const SizedBox(width: 8),
                  _circleBtn(Iconsax.refresh, _load),
                ]),
              const SizedBox(height: 24),

              // Gran cifra de ganancias
              Text('GANANCIAS TOTALES',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.45), letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${_fmtMoney(ganancias)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 38, fontWeight: FontWeight.w800,
                        color: AppTheme.primary, height: 1.1)),
                  const SizedBox(width: 12),
                  if (last30 > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.arrow_up,
                              color: Color(0xFF4ADE80), size: 13),
                          const SizedBox(width: 3),
                          Text('${growthPct.toStringAsFixed(0)}% este mes',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4ADE80))),
                        ])),
                ]),
              const SizedBox(height: 20),

              // 4 KPIs en fila
              Row(
                children: [
                  _kpiCard(Iconsax.wallet, '\$${_fmtMoney(last30)}', 'Últimos\n30 días'),
                  const SizedBox(width: 10),
                  _kpiCard(Iconsax.box, '$pedidos', 'Total\npedidos'),
                  const SizedBox(width: 10),
                  _kpiCard(Iconsax.tick_circle, '$entregados', 'Pedidos\nentregados'),
                  const SizedBox(width: 10),
                  _kpiCard(
                    rating > 0 ? Iconsax.star : Iconsax.shop,
                    rating > 0 ? rating.toStringAsFixed(1) : '$activos',
                    rating > 0 ? 'Rating\npromedio' : 'Productos\nactivos'),
                ]),
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

  Widget _kpiCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF131C13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.45)),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary),
                textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.45), height: 1.3),
                textAlign: TextAlign.center),
          ])));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB BAR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14)),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textMuted,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 8, offset: const Offset(0, 2)),
          ]),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Ganancias'),
          Tab(text: 'Pedidos'),
          Tab(text: 'Productos'),
        ]));
  }

  Widget _buildActiveTab() {
    final s = _stats;
    if (s == null) return const SizedBox.shrink();
    switch (_tabCtrl.index) {
      case 0: return _tabGanancias(s);
      case 1: return _tabPedidos(s);
      case 2: return _tabProductos(s);
      default: return _tabGanancias(s);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 1 — GANANCIAS
  // ═══════════════════════════════════════════════════════════════════
  Widget _tabGanancias(Map<String, dynamic> s) {
    final ventasDia = (s['ventasPorDia'] as Map<String, double>?) ?? {};
    final catVentas = (s['categoriaVentas'] as Map<String, double>?) ?? {};
    final total = _safeInt(s['totalPedidos']);
    final entregados = _safeInt(s['entregados']);
    final cancelados = _safeInt(s['cancelados']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gráfico de línea ──────────────────────────────
          _card(
            title: 'Ingresos — Últimos 7 días',
            subtitle: 'Dinero de pedidos entregados por día',
            child: _lineChart(ventasDia)),
          const SizedBox(height: 20),

          // ── Torta de categorías ────────────────────────────
          _card(
            title: 'Ganancias por categoría',
            subtitle: 'Distribución de ingresos',
            child: _categoriaPie(catVentas)),
          const SizedBox(height: 20),

          // ── Tasa de éxito ─────────────────────────────────
          _card(
            title: 'Rendimiento general',
            child: _conversionVisual(total, entregados, cancelados)),
        ]));
  }

  // ── Line Chart ─────────────────────────────────────────────────────
  Widget _lineChart(Map<String, double> data) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return _emptyState('Aún no hay ingresos esta semana');
    }

    final keys = data.keys.toList();
    final vals = data.values.toList();
    final maxY = vals.reduce((a, b) => a > b ? a : b);
    final ceiling = maxY == 0 ? 10.0 : (maxY * 1.25);

    return SizedBox(
      height: 210,
      child: LineChart(LineChartData(
        minY: 0, maxY: ceiling,
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: ceiling / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: const Color(0xFFE2E8F0), strokeWidth: 1)),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28, interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= keys.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(keys[i], style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8))));
            })),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 48,
            getTitlesWidget: (v, _) => Text(
              _fmtMoneyShort(v),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9, color: const Color(0xFF94A3B8)))))),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [for (int i = 0; i < vals.length; i++) FlSpot(i.toDouble(), vals[i])],
            isCurved: true, curveSmoothness: 0.35,
            color: AppTheme.primary, barWidth: 3, isStrokeCapRound: true,
            dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
              FlDotCirclePainter(radius: 4, color: AppTheme.primary,
                  strokeWidth: 2.5, strokeColor: AppTheme.primary)),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                AppTheme.primary.withValues(alpha: 0.25),
                AppTheme.primary.withValues(alpha: 0.0),
              ]))),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E293B),
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '\$${_fmtMoney(s.y)}',
              GoogleFonts.plusJakartaSans(fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppTheme.primary))).toList())))));
  }

  // ── Pie Chart categorías ───────────────────────────────────────────
  Widget _categoriaPie(Map<String, double> data) {
    if (data.isEmpty) return _emptyState('Sin ventas por categoría');

    final totalCat = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        SizedBox(
          width: 140, height: 140,
          child: PieChart(PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  _touchedPieIndex = (event.isInterestedForInteractions &&
                      response != null && response.touchedSection != null)
                      ? response.touchedSection!.touchedSectionIndex : -1;
                });
              }),
            sections: entries.asMap().entries.map((e) {
              final i = e.key;
              final pct = e.value.value / totalCat * 100;
              final isTouched = i == _touchedPieIndex;
              return PieChartSectionData(
                value: e.value.value,
                color: _catColors[i % _catColors.length],
                radius: isTouched ? 62 : 52,
                title: '${pct.toStringAsFixed(0)}%',
                titleStyle: GoogleFonts.plusJakartaSans(
                    fontSize: isTouched ? 13 : 11,
                    fontWeight: FontWeight.w800, color: AppTheme.primary));
            }).toList(),
            centerSpaceRadius: 28,
            sectionsSpace: 2))),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((e) {
              final i = e.key;
              final isTouched = i == _touchedPieIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _catColors[i % _catColors.length],
                        borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value.key,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13,
                            fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
                            color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('\$${_fmtMoney(e.value.value)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isTouched ? AppTheme.primary : AppTheme.textMuted)),
                  ]));
            }).toList())),
      ]);
  }

  // ── Conversion / Rendimiento ───────────────────────────────────────
  Widget _conversionVisual(int total, int entregados, int cancelados) {
    if (total == 0) return _emptyState('Sin pedidos aún');
    final sinResolver = total - entregados - cancelados;
    final pctEntrega = entregados / total * 100;
    final pctCancel = cancelados / total * 100;

    return Column(
      children: [
        Row(
          children: [
            _metricBig('${pctEntrega.toStringAsFixed(0)}%', 'Tasa de\nentrega',
                AppTheme.success, Iconsax.tick_circle),
            const SizedBox(width: 12),
            _metricBig('${pctCancel.toStringAsFixed(0)}%', 'Tasa de\ncancelación',
                AppTheme.error, Iconsax.close_circle),
            const SizedBox(width: 12),
            _metricBig('$sinResolver', 'Sin\nresolver',
                AppTheme.warning, Iconsax.clock),
          ]),
        const SizedBox(height: 16),
        // Barra de proporción
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (entregados > 0)
                  Flexible(flex: entregados, child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppTheme.success, AppTheme.success.withValues(alpha: 0.8)])))),
                if (cancelados > 0)
                  Flexible(flex: cancelados, child: Container(color: AppTheme.error)),
                if (sinResolver > 0)
                  Flexible(flex: sinResolver, child: Container(color: AppTheme.warning)),
              ]))),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(AppTheme.success, 'Entregados'),
            const SizedBox(width: 16),
            _legendDot(AppTheme.error, 'Cancelados'),
            const SizedBox(width: 16),
            _legendDot(AppTheme.warning, 'En proceso'),
          ]),
      ]);
  }

  Widget _metricBig(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.45), height: 1.3),
                textAlign: TextAlign.center),
          ])));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 2 — PEDIDOS
  // ═══════════════════════════════════════════════════════════════════
  Widget _tabPedidos(Map<String, dynamic> s) {
    final total = _safeInt(s['totalPedidos']);
    final pedidosDia = (s['pedidosPorDia'] as Map<String, int>?) ?? {};
    final rating = _safeDouble(s['ratingAvg']);
    final ratingCount = _safeInt(s['ratingCount']);

    final estados = [
      ('Pendientes', _safeInt(s['pendientes']), const Color(0xFFFBBF24), Iconsax.clock),
      ('Confirmados', _safeInt(s['confirmados']), const Color(0xFF6366F1), Iconsax.like_1),
      ('Entregados', _safeInt(s['entregados']), const Color(0xFF16A34A), Iconsax.tick_circle),
      ('Cancelados', _safeInt(s['cancelados']), const Color(0xFFEF4444), Iconsax.close_circle),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Distribución por estado ────────────────────────
          _card(
            title: 'Estado de pedidos',
            subtitle: '$total pedidos en total',
            child: total == 0
              ? _emptyState('Aún no tienes pedidos')
              : Column(
                  children: [
                    // Donut chart
                    SizedBox(
                      height: 180,
                      child: PieChart(PieChartData(
                        sections: estados.where((e) => e.$2 > 0).map((item) {
                          final pct = item.$2 / total * 100;
                          return PieChartSectionData(
                            value: item.$2.toDouble(),
                            color: item.$3,
                            radius: 55, title: '${pct.toStringAsFixed(0)}%',
                            titleStyle: GoogleFonts.plusJakartaSans(fontSize: 12,
                                fontWeight: FontWeight.w800, color: AppTheme.primary));
                        }).toList(),
                        centerSpaceRadius: 38, sectionsSpace: 3))),
                    const SizedBox(height: 16),
                    // Estado cards
                    Row(
                      children: estados.map((item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: item.$3.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Icon(item.$4, color: item.$3, size: 18),
                                const SizedBox(height: 4),
                                Text('${item.$2}', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, fontWeight: FontWeight.w800,
                                    color: item.$3)),
                                Text(item.$1, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8, fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.45))),
                              ]))))).toList()),
                  ])),
          const SizedBox(height: 20),

          // ── Frecuencia diaria ──────────────────────────────
          _card(
            title: 'Actividad — Últimos 7 días',
            subtitle: 'Pedidos entregados por día',
            child: _barChart(pedidosDia)),
          const SizedBox(height: 20),

          // ── Rating ─────────────────────────────────────────
          if (ratingCount > 0) _card(
            title: 'Tu reputación',
            child: Row(
              children: [
                // Número grande
                Column(
                  children: [
                    Text(rating.toStringAsFixed(1),
                        style: GoogleFonts.plusJakartaSans(fontSize: 52,
                            fontWeight: FontWeight.w800, color: Colors.white)),
                    Row(children: List.generate(5, (i) => Icon(
                      i < rating.round() ? Iconsax.star5 : Iconsax.star,
                      color: const Color(0xFFFBBF24), size: 20))),
                  ]),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$ratingCount reseña${ratingCount != 1 ? 's' : ''}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        rating >= 4.5 ? '¡Excelente! Tus clientes te aman.' :
                        rating >= 3.5 ? 'Buen trabajo, sigue así.' :
                        rating >= 2.5 ? 'Hay espacio para mejorar.' :
                        'Enfócate en la calidad del servicio',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45), height: 1.4)),
                    ])),
              ])),
        ]));
  }

  // ── Bar Chart pedidos ──────────────────────────────────────────────
  Widget _barChart(Map<String, int> data) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return _emptyState('Sin pedidos esta semana');
    }

    final keys = data.keys.toList();
    final vals = data.values.toList();
    final maxV = vals.reduce((a, b) => a > b ? a : b).toDouble();
    final ceil = (maxV + 1).clamp(2.0, double.infinity);

    return SizedBox(
      height: 190,
      child: BarChart(BarChartData(
        maxY: ceil,
        gridData: FlGridData(show: true, drawVerticalLine: false,
          horizontalInterval: (ceil / 3).clamp(1, double.infinity),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1)),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28, interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= keys.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 8),
                child: Text(keys[i], style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8))));
            })),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            interval: (ceil / 3).clamp(1, double.infinity),
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, color: const Color(0xFF94A3B8)))))),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(vals.length, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: vals[i].toDouble(), color: AppTheme.primary, width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true, toY: ceil,
              color: AppTheme.primary.withValues(alpha: 0.05)))])),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E293B),
            tooltipRoundedRadius: 10,
            getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
              '${rod.toY.toInt()} pedidos',
              GoogleFonts.plusJakartaSans(fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppTheme.primary)))))));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 3 — PRODUCTOS
  // ═══════════════════════════════════════════════════════════════════
  Widget _tabProductos(Map<String, dynamic> s) {
    final top = (s['topProductos'] as List).cast<Map<String, dynamic>>();
    final activos = _safeInt(s['productosActivos']);
    final rating = _safeDouble(s['ratingAvg']);
    final ratingCount = _safeInt(s['ratingCount']);
    final ganancias = _safeDouble(s['totalVentas']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top productos ──────────────────────────────────
          _card(
            title: 'Productos más vendidos',
            subtitle: 'Ranking por cantidad de pedidos',
            child: top.isEmpty
              ? _emptyState('Aún sin datos de ventas')
              : _topProductsList(top)),
          const SizedBox(height: 20),

          // ── Resumen rápido ─────────────────────────────────
          _card(
            title: 'Resumen de tu tienda',
            child: Column(
              children: [
                _infoRow(Iconsax.shop, 'Productos activos',
                    '$activos', const Color(0xFF6366F1)),
                _divider(),
                _infoRow(Iconsax.star5, 'Calificación',
                    rating > 0
                        ? '${rating.toStringAsFixed(1)} ($ratingCount reseñas)'
                        : 'Sin reseñas',
                    const Color(0xFFFBBF24)),
                _divider(),
                _infoRow(Iconsax.wallet, 'Ganancias totales',
                    '\$${_fmtMoney(ganancias)}', AppTheme.success),
                _divider(),
                _infoRow(Iconsax.truck, 'Pedidos entregados',
                    '${_safeInt(s['entregados'])}', AppTheme.primary),
              ])),
        ]));
  }

  Widget _topProductsList(List<Map<String, dynamic>> top) {
    final maxP = top.map((e) => e['pedidos'] as int).reduce((a, b) => a > b ? a : b);
    return Column(
      children: top.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        final count = p['pedidos'] as int;
        final pct = maxP > 0 ? count / maxP : 0.0;
        final color = _catColors[i % _catColors.length];
        final isFirst = i == 0;

        return Padding(
          padding: EdgeInsets.only(bottom: i < top.length - 1 ? 14 : 0),
          child: Row(
            children: [
              // Posición
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isFirst ? const Color(0xFFFBBF24) : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
                child: Center(child: isFirst
                  ? const Icon(Iconsax.cup, size: 16, color: AppTheme.primary)
                  : Text('${i + 1}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12,
                          fontWeight: FontWeight.w800, color: color)))),
              const SizedBox(width: 12),
              // Nombre y barra
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['nombre'] as String,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13,
                            fontWeight: FontWeight.w600, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6)),
                  ])),
              const SizedBox(width: 12),
              // Cantidad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text('$count', style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color))),
            ]));
      }).toList());
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WIDGETS COMPARTIDOS
  // ═══════════════════════════════════════════════════════════════════

  Widget _card({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131C13),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12, offset: const Offset(0, 4)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
          ],
          const SizedBox(height: 16),
          child,
        ]));
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Column(
        children: [
          Icon(Iconsax.chart_2,
              color: Colors.white.withValues(alpha: 0.45).withValues(alpha: 0.25), size: 40),
          const SizedBox(height: 8),
          Text(text, style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
        ])));
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
          Text(value, style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ]));
  }

  Widget _divider() => Divider(height: 16, color: const Color(0xFFF1F5F9));

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: Colors.white.withValues(alpha: 0.45))),
      ]);
  }

  String _fmtMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtMoneyShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
