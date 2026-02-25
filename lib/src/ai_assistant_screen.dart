import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  Map<String, int> _categoryCounts = {};
  Map<String, Map<String, dynamic>> _priceStats = {};

  final List<String> _categorias = [
    'Frutas',
    'Verduras',
    'Artesanías',
    'Gastronomía',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final counts = await _firestoreService.getProductCountByCategory();
    final Map<String, Map<String, dynamic>> stats = {};

    for (var cat in _categorias) {
      stats[cat] = await _firestoreService.getPriceStats(cat);
    }

    if (mounted) {
      setState(() {
        _categoryCounts = counts;
        _priceStats = stats;
        _isLoading = false;
      });
    }
  }

  int get _totalProducts => _categoryCounts.values.fold(0, (a, b) => a + b);

  String get _topCategory {
    if (_categoryCounts.isEmpty) return 'N/A';
    final sorted = _categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String get _leastCategory {
    if (_categoryCounts.isEmpty) return 'N/A';
    final categoriesWithProducts =
        _categoryCounts.entries.where((e) => e.value > 0).toList();
    if (categoriesWithProducts.isEmpty) return _categorias.first;
    categoriesWithProducts.sort((a, b) => a.value.compareTo(b.value));
    return categoriesWithProducts.first.key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.orange))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSummaryCards()),
                  SliverToBoxAdapter(child: _buildSectionTitle('Productos por Categoría')),
                  SliverToBoxAdapter(child: _buildCategoryBars()),
                  SliverToBoxAdapter(child: _buildSectionTitle('Análisis de Precios')),
                  SliverToBoxAdapter(child: _buildPriceAnalysis()),
                  SliverToBoxAdapter(child: _buildSectionTitle('Recomendaciones IA')),
                  SliverToBoxAdapter(child: _buildRecommendations()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(gradient: AppTheme.orangeGradient),
      child: Column(
        children: [
          Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asistente IA',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text('Inteligencia de negocios para Urabá',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _summaryCard(
            Icons.inventory_2_rounded,
            '$_totalProducts',
            'Productos activos',
            AppTheme.orange,
          ),
          const SizedBox(width: 12),
          _summaryCard(
            Icons.category_rounded,
            _topCategory,
            'Categoría top',
            AppTheme.green,
          ),
          const SizedBox(width: 12),
          _summaryCard(
            Icons.trending_up_rounded,
            _leastCategory,
            'Oportunidad',
            AppTheme.info,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusM,
          boxShadow: [AppTheme.shadowSmall],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, color: AppTheme.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(title, style: AppTheme.heading3),
    );
  }

  Widget _buildCategoryBars() {
    final maxCount = _categoryCounts.values.isEmpty
        ? 1
        : _categoryCounts.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: [AppTheme.shadowSmall],
        ),
        child: Column(
          children: _categorias.map((cat) {
            final count = _categoryCounts[cat] ?? 0;
            final fraction = maxCount > 0 ? count / maxCount : 0.0;
            final style = AppTheme.getCategoryStyle(cat);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(style['icon'] as IconData,
                      color: style['accent'] as Color, size: 18),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(cat,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: AppTheme.bg,
                        color: style['accent'] as Color,
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text('$count',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                        textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriceAnalysis() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _categorias.map((cat) {
          final stats = _priceStats[cat] ?? {};
          final count = stats['count'] ?? 0;
          if (count == 0) return const SizedBox.shrink();

          final avg = (stats['avg'] ?? 0).toDouble();
          final min = (stats['min'] ?? 0).toDouble();
          final max = (stats['max'] ?? 0).toDouble();
          final style = AppTheme.getCategoryStyle(cat);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.radiusM,
              boxShadow: [AppTheme.shadowSmall],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(style['icon'] as IconData,
                        color: style['accent'] as Color, size: 18),
                    const SizedBox(width: 8),
                    Text(cat,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const Spacer(),
                    Text('$count productos', style: AppTheme.caption),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _priceChip('Mín', '\$${min.toStringAsFixed(0)}',
                        AppTheme.success),
                    const SizedBox(width: 8),
                    _priceChip('Prom', '\$${avg.toStringAsFixed(0)}',
                        AppTheme.info),
                    const SizedBox(width: 8),
                    _priceChip('Máx', '\$${max.toStringAsFixed(0)}',
                        AppTheme.warning),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _priceChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: AppTheme.radiusS,
        ),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color)),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    // Generar recomendaciones basadas en datos
    if (_categoryCounts.isNotEmpty) {
      final sorted = _categoryCounts.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final least = sorted.first;

      recommendations.add({
        'icon': Icons.lightbulb_outline_rounded,
        'color': AppTheme.warning,
        'title': 'Oportunidad en ${least.key}',
        'desc':
            'Solo hay ${least.value} productos en esta categoría. ¡Es un buen momento para publicar!',
      });
    }

    // Recomendación de precio
    for (var cat in _categorias) {
      final stats = _priceStats[cat];
      if (stats != null && (stats['count'] ?? 0) >= 3) {
        final avg = (stats['avg'] ?? 0).toDouble();
        if (avg > 0) {
          recommendations.add({
            'icon': Icons.attach_money_rounded,
            'color': AppTheme.success,
            'title': 'Precio sugerido en $cat',
            'desc':
                'El precio promedio es \$${avg.toStringAsFixed(0)}. Publicar cerca de este precio mejora la visibilidad.',
          });
          break;
        }
      }
    }

    recommendations.add({
      'icon': Icons.description_outlined,
      'color': AppTheme.info,
      'title': 'Mejora tus publicaciones',
      'desc':
          'Los productos con descripción detallada reciben más interés. Incluye variedad, origen y características.',
    });

    recommendations.add({
      'icon': Icons.people_outline_rounded,
      'color': AppTheme.orange,
      'title': 'Conecta con compradores',
      'desc':
          'Usa la mensajería para responder rápido y generar confianza con tus clientes.',
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: recommendations
            .map((r) => _recommendationCard(r))
            .toList(),
      ),
    );
  }

  Widget _recommendationCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusM,
        boxShadow: [AppTheme.shadowSmall],
        border: Border.all(
          color: (r['color'] as Color).withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (r['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(r['icon'] as IconData,
                color: r['color'] as Color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(r['desc'] as String,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
