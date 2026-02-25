import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'nombre';
  bool _showFilters = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Todas', 'value': null, 'icon': Icons.grid_view_rounded},
    {'label': 'Frutas', 'value': 'Frutas', 'icon': Icons.eco_rounded},
    {'label': 'Verduras', 'value': 'Verduras', 'icon': Icons.grass_rounded},
    {
      'label': 'Artesanías',
      'value': 'Artesanías',
      'icon': Icons.palette_rounded
    },
    {
      'label': 'Gastronomía',
      'value': 'Gastronomía',
      'icon': Icons.restaurant_rounded
    },
    {'label': 'Otros', 'value': 'Otros', 'icon': Icons.inventory_2_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildSearchHeader(),
          if (_showFilters) _buildFilters(),
          _buildCategoryChips(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buscar', style: AppTheme.heading2),
          const SizedBox(height: 4),
          Text('Encuentra productos y comerciantes',
              style: AppTheme.bodyMuted),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.radiusL,
              boxShadow: [AppTheme.shadowSmall],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: AppTheme.body,
              decoration: InputDecoration(
                hintText: 'Buscar productos, comerciantes...',
                hintStyle: AppTheme.bodyMuted,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textMuted, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: AppTheme.textMuted, size: 18),
                      ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showFilters = !_showFilters),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _showFilters
                              ? AppTheme.orange.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: AppTheme.radiusS,
                        ),
                        child: Icon(Icons.tune_rounded,
                            color: _showFilters
                                ? AppTheme.orange
                                : AppTheme.textMuted,
                            size: 18),
                      ),
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusM,
        boxShadow: [AppTheme.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ordenar por',
              style: AppTheme.label),
          const SizedBox(height: 8),
          Row(
            children: [
              _sortChip('Nombre', 'nombre'),
              const SizedBox(width: 8),
              _sortChip('Precio ↑', 'precio_asc'),
              const SizedBox(width: 8),
              _sortChip('Precio ↓', 'precio_desc'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.orange : AppTheme.bg,
          borderRadius: AppTheme.radiusS,
          border: Border.all(
            color: selected ? AppTheme.orange : AppTheme.border,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            )),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat['value'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedCategory = cat['value'] as String?),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.orange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.orange : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData,
                      size: 14,
                      color: selected ? Colors.white : AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(cat['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.textSecondary,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    Query query = FirebaseFirestore.instance
        .collection('productos')
        .where('activo', isEqualTo: true);

    if (_selectedCategory != null) {
      query = query.where('categoria', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }

        var docs = snapshot.data?.docs ?? [];

        // Filtrar por búsqueda local (Firestore no soporta búsqueda de texto nativa)
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = (data['nombre'] ?? '').toString().toLowerCase();
            final vendedor = (data['vendedor'] ?? '').toString().toLowerCase();
            final desc =
                (data['descripcion'] ?? '').toString().toLowerCase();
            return nombre.contains(q) ||
                vendedor.contains(q) ||
                desc.contains(q);
          }).toList();
        }

        // Ordenar
        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          if (_sortBy == 'precio_asc') {
            return ((da['precio'] ?? 0) as num)
                .compareTo((db['precio'] ?? 0) as num);
          } else if (_sortBy == 'precio_desc') {
            return ((db['precio'] ?? 0) as num)
                .compareTo((da['precio'] ?? 0) as num);
          }
          return (da['nombre'] ?? '')
              .toString()
              .compareTo((db['nombre'] ?? '').toString());
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No se encontraron resultados para "$_searchQuery"'
                      : 'No hay productos en esta categoría',
                  style: AppTheme.bodyMuted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final style = AppTheme.getCategoryStyle(data['categoria']);
            return _buildResultCard(docs[i].id, data, style);
          },
        );
      },
    );
  }

  Widget _buildResultCard(
      String productId, Map<String, dynamic> data, Map<String, dynamic> style) {
    final nombre = data['nombre'] ?? 'Producto';
    final vendedor = data['vendedor'] ?? 'Comerciante';
    final precio = data['precio'];
    final unidad = data['unidad'] ?? 'c/u';
    final precioStr = precio != null ? '\$${precio.toString()}' : 'Consultar';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: productId,
            productData: data,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: [AppTheme.shadowSmall],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: style['color'] as Color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(style['icon'] as IconData,
                    color: style['accent'] as Color, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(vendedor,
                    style: AppTheme.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(precioStr,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.orange)),
                        Text(unidad, style: AppTheme.caption),
                      ],
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: AppTheme.radiusS,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
