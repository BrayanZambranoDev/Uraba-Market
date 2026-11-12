import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'product_detail_screen.dart';
import 'constants/app_constants.dart';
import 'services/firestore_service.dart';
import 'utils/shimmer_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'nombre';
  bool _showFilters = false;
  RangeValues _priceRange = const RangeValues(0, 200000);
  static const double _priceMin = 0;
  static const double _priceMax = 200000;
  List<String> _searchHistory = [];
  bool _isGridView = true;
  bool _soloEnStock = false;
  String? _selectedMunicipio;
  double _minRating = 0.0;
  int _pageLimit = 30;

  Timer? _debounceTimer;
  Timer? _suggestTimer;
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;
  Set<String> _favorites = {};
  StreamSubscription<List<String>>? _favoritesSub;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    if (_user != null) {
      _favoritesSub =
          _firestoreService.getFavoritesStream(_user!.uid).listen((ids) {
        if (mounted) setState(() => _favorites = Set<String>.from(ids));
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _searchHistory = prefs.getStringList('search_history') ?? [];
      });
    }
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Todas', 'value': null, 'icon': Iconsax.element_3},
    ...AppConstants.categorias.map((cat) => {
          'label': cat,
          'value': cat,
          'icon': _iconForCategory(cat),
        }),
  ];

  static IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Frutas':
        return Iconsax.sun_1;
      case 'Verduras':
        return Iconsax.health;
      case 'Artesanías':
        return Iconsax.gift;
      case 'Gastronomía':
        return Iconsax.cup;
      default:
        return Iconsax.category;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestTimer?.cancel();
    _favoritesSub?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0F0A),
      child: SafeArea(
      child: Column(
        children: [
          _buildSearchHeader(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _showFilters ? _buildFilters() : const SizedBox.shrink(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _searchQuery.isEmpty && _searchHistory.isNotEmpty
                ? _buildSearchHistory()
                : const SizedBox.shrink(),
          ),
          if (_showSuggestions && _suggestions.isNotEmpty)
            _buildSuggestions(),
          _buildCategoryChips(),
          Expanded(child: _buildResults()),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: const Color(0xFF0A0F0A),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.onBack != null) ...[
                    GestureDetector(
                      onTap: widget.onBack,
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
                  ],
                  Text('Buscar 🌿',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isGridView = !_isGridView),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F0A),
                        borderRadius: AppTheme.radiusS,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(
                        _isGridView
                            ? Iconsax.row_vertical
                            : Iconsax.element_3,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty || _selectedCategory != null ||
                      _sortBy != 'nombre' ||
                      _priceRange.start > _priceMin ||
                      _priceRange.end < _priceMax ||
                      _soloEnStock ||
                      _selectedMunicipio != null ||
                      _minRating > 0) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _selectedCategory = null;
                          _sortBy = 'nombre';
                          _showFilters = false;
                          _soloEnStock = false;
                          _priceRange = const RangeValues(_priceMin, _priceMax);
                          _selectedMunicipio = null;
                          _minRating = 0.0;
                          _pageLimit = 30;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: AppTheme.radiusFull,
                        ),
                        child: Text('Limpiar',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.error)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Encuentra productos locales del Urabá',
              style: AppTheme.bodyMuted),
          const SizedBox(height: 14),
          // Campo de búsqueda
          Container(
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: AppTheme.radiusFull,
              border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppTheme.primary
                      : Colors.transparent,
                  width: _focusNode.hasFocus ? 1.5 : 1),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (val) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() { _searchQuery = val.trim(); _pageLimit = 30; });
                });
                // Sugerencias inteligentes
                _suggestTimer?.cancel();
                _suggestTimer = Timer(const Duration(milliseconds: 250), () async {
                  if (!mounted) return;
                  if (val.trim().length < 2) {
                    setState(() { _suggestions = []; _showSuggestions = false; });
                    return;
                  }
                  final s = await _firestoreService.getSearchSuggestions(val.trim());
                  if (mounted) setState(() { _suggestions = s; _showSuggestions = s.isNotEmpty; });
                });
              },
              onSubmitted: (val) {
                final q = val.trim();
                if (q.isNotEmpty) {
                  setState(() {
                    _searchHistory.remove(q);
                    _searchHistory.insert(0, q);
                    if (_searchHistory.length > 5) _searchHistory.removeLast();
                  });
                  _saveSearchHistory();
                }
              },
              onTap: () => setState(() {}),
              onEditingComplete: () => setState(() {}),
              style: AppTheme.body,
              decoration: InputDecoration(
                hintText: 'Buscar productos, comerciantes...',
                hintStyle: AppTheme.bodyMuted,
                prefixIcon: const Icon(Iconsax.search_normal,
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
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.textMuted
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.close_circle,
                              color: AppTheme.textSecondary, size: 14),
                        ),
                      ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showFilters = !_showFilters),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _showFilters
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: AppTheme.radiusS,
                        ),
                        child: Icon(Iconsax.setting_4,
                            color: _showFilters
                                ? Colors.white
                                : AppTheme.primary,
                            size: 16),
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

  Widget _buildSuggestions() {
    return Container(
      color: const Color(0xFF0A0F0A),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sugerencias', style: AppTheme.label),
          const SizedBox(height: 6),
          ..._suggestions.map((s) => GestureDetector(
            onTap: () {
              _searchController.text = s;
              setState(() {
                _searchQuery = s;
                _showSuggestions = false;
                _searchHistory.remove(s);
                _searchHistory.insert(0, s);
                if (_searchHistory.length > 5) _searchHistory.removeLast();
              });
              _saveSearchHistory();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(Iconsax.search_normal,
                      size: 16, color: AppTheme.primary.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                  const Icon(Iconsax.arrow_left_1,
                      size: 14, color: AppTheme.textMuted),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Container(
      color: const Color(0xFF0A0F0A),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Búsquedas recientes', style: AppTheme.label),
              GestureDetector(
                onTap: () { setState(() => _searchHistory.clear()); _saveSearchHistory(); },
                child: Text('Limpiar',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((term) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = term;
                  setState(() => _searchQuery = term);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F0A),
                    borderRadius: AppTheme.radiusFull,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.clock,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 5),
                      Text(term,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final priceActive =
        _priceRange.start > _priceMin || _priceRange.end < _priceMax;

    String fmt(double v) {
      if (v >= 1000) {
        return '\$${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
      }
      return '\$${v.toInt()}';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusL,
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ordenar ──
          Row(children: [
            const Icon(Iconsax.sort, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            Text('Ordenar por', style: AppTheme.label),
          ]),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _sortChip('Nombre', 'nombre', Iconsax.text),
                const SizedBox(width: 8),
                _sortChip('Precio ↑', 'precio_asc', Iconsax.trend_up),
                const SizedBox(width: 8),
                _sortChip('Precio ↓', 'precio_desc', Iconsax.trend_down),
                const SizedBox(width: 8),
                _sortChip('Mejor rated', 'rating', Iconsax.star5),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Rango de precio ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Iconsax.dollar_circle,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text('Rango de precio', style: AppTheme.label),
              ]),
              if (priceActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: AppTheme.radiusFull,
                  ),
                  child: Text(
                    '${fmt(_priceRange.start)} — ${fmt(_priceRange.end)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.border,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.15),
              valueIndicatorColor: AppTheme.primary,
              trackHeight: 3,
              rangeValueIndicatorShape:
                  const PaddleRangeSliderValueIndicatorShape(),
              showValueIndicator: ShowValueIndicator.onDrag,
            ),
            child: RangeSlider(
              values: _priceRange,
              min: _priceMin,
              max: _priceMax,
              divisions: 40,
              labels: RangeLabels(
                fmt(_priceRange.start),
                fmt(_priceRange.end),
              ),
              onChanged: (vals) => setState(() => _priceRange = vals),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt(_priceMin), style: AppTheme.caption),
              Text(fmt(_priceMax), style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: 16),
          // ── Municipio ──
          Row(children: [
            const Icon(Iconsax.location,
                size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            Text('Municipio', style: AppTheme.label),
            if (_selectedMunicipio != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _selectedMunicipio = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: AppTheme.radiusFull,
                  ),
                  child: Text(_selectedMunicipio!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.municipios.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final mun = AppConstants.municipios[i];
                final sel = _selectedMunicipio == mun;
                return GestureDetector(
                  onTap: () => setState(() =>
                      _selectedMunicipio = sel ? null : mun),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : AppTheme.bg,
                      borderRadius: AppTheme.radiusFull,
                      border: Border.all(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.border),
                    ),
                    child: Text(mun,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? Colors.white
                                : AppTheme.textSecondary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // ── Rating mínimo ──
          Row(children: [
            const Icon(Iconsax.star5,
                size: 14, color: AppTheme.surface),
            const SizedBox(width: 6),
            Text('Calificación mínima', style: AppTheme.label),
            if (_minRating > 0) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _minRating = 0.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.15),
                    borderRadius: AppTheme.radiusFull,
                  ),
                  child: Text('≥ ${_minRating.toStringAsFixed(1)} ★',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309))),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Row(
            children: [1.0, 2.0, 3.0, 4.0, 4.5].map((val) {
              final sel = _minRating == val;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _minRating = sel ? 0.0 : val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFFBBF24)
                          : AppTheme.bg,
                      borderRadius: AppTheme.radiusFull,
                      border: Border.all(
                          color: sel
                              ? const Color(0xFFFBBF24)
                              : AppTheme.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Iconsax.star5,
                          size: 12,
                          color: sel
                              ? Colors.white
                              : const Color(0xFFFBBF24)),
                      const SizedBox(width: 3),
                      Text(val.toStringAsFixed(val % 1 == 0 ? 0 : 1),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? Colors.white
                                  : AppTheme.textSecondary)),
                      Text('+',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? Colors.white70
                                  : AppTheme.textMuted)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Toggle solo en stock
          GestureDetector(
            onTap: () => setState(() => _soloEnStock = !_soloEnStock),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: _soloEnStock ? AppTheme.green : AppTheme.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: _soloEnStock
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('Solo productos en stock',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _soloEnStock
                          ? AppTheme.green
                          : AppTheme.textSecondary)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value, IconData icon) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.orangeGradient : null,
          color: selected ? null : AppTheme.bg,
          borderRadius: AppTheme.radiusFull,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13,
              color: selected ? Colors.white : AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSecondary,
              )),
        ]),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: AppTheme.surface,
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final cat = _categories[i];
            final selected = _selectedCategory == cat['value'];
            return GestureDetector(
              onTap: () => setState(() {
                    _selectedCategory = cat['value'] as String?;
                    _pageLimit = 30;
                  }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: selected ? AppTheme.orangeGradient : null,
                  color: selected ? null : AppTheme.bg,
                  borderRadius: AppTheme.radiusFull,
                  border: Border.all(
                    color:
                        selected ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData,
                        size: 13,
                        color: selected ? Colors.white : AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(cat['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults() {
    // Cuando hay texto de búsqueda, filtrar por prefijo en servidor
    // (isGreaterThanOrEqualTo) para evitar cargar todos los productos.
    // Con categoría o filtros activos, cargamos hasta 120 y filtramos en cliente.
    final bool priceFiltroActivo =
        _priceRange.start > _priceMin || _priceRange.end < _priceMax;

    Query query;
    if (_searchQuery.isNotEmpty &&
        !priceFiltroActivo &&
        !_soloEnStock &&
        _selectedCategory == null) {
      // Búsqueda por prefijo en servidor — rápida, sin cargar todo
      query = FirebaseFirestore.instance
          .collection('productos')
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .where('nombre', isGreaterThanOrEqualTo: _searchQuery)
          .where('nombre', isLessThan: '$_searchQuery\uf8ff')
          .limit(40);
    } else {
      query = FirebaseFirestore.instance
          .collection('productos')
          .where('activo', isEqualTo: true);
      if (_selectedCategory != null) {
        query = query.where('categoria', isEqualTo: _selectedCategory);
      }
      query = query.limit(_pageLimit);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildGridShimmer();
        }

        var docs = snapshot.data?.docs ?? [];
        final rawCount = docs.length; // antes de filtros client-side

        // Filtro de texto en cliente solo cuando hay filtros activos
        if (_searchQuery.isNotEmpty && (priceFiltroActivo || _soloEnStock || _selectedCategory != null)) {
          final q = _searchQuery.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = (data['nombre'] ?? '').toString().toLowerCase();
            final vendedor =
                (data['vendedor'] ?? '').toString().toLowerCase();
            final desc =
                (data['descripcion'] ?? '').toString().toLowerCase();
            return nombre.contains(q) ||
                vendedor.contains(q) ||
                desc.contains(q);
          }).toList();
        }

        // Filtro de rango de precio
        if (_priceRange.start > _priceMin || _priceRange.end < _priceMax) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final precio = (data['precio'] as num?)?.toDouble() ?? 0;
            return precio >= _priceRange.start && precio <= _priceRange.end;
          }).toList();
        }

        // Filtro solo en stock
        if (_soloEnStock) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ((data['stock'] as num?)?.toInt() ?? 0) > 0;
          }).toList();
        }

        // Filtro por municipio
        if (_selectedMunicipio != null) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['municipio'] == _selectedMunicipio;
          }).toList();
        }

        // Filtro por rating mínimo
        if (_minRating > 0) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final avg = (data['ratingAvg'] as num?)?.toDouble() ?? 0.0;
            return avg >= _minRating;
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
          } else if (_sortBy == 'rating') {
            final ra = (da['ratingAvg'] as num?)?.toDouble() ?? 0.0;
            final rb = (db['ratingAvg'] as num?)?.toDouble() ?? 0.0;
            return rb.compareTo(ra);
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: const Color(0xFF0A0F0A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.search_status,
                      size: 40, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Sin resultados para "$_searchQuery"'
                      : 'No hay productos en esta categoría',
                  style: AppTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text('Intenta con otro término o categoría',
                    style: AppTheme.bodyMuted),
              ],
            ),
          );
        }

        // Mostrar conteo de resultados
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                '${docs.length} resultado${docs.length != 1 ? 's' : ''}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted),
              ),
            ),
            Expanded(
              child: _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.76,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final style =
                            AppTheme.getCategoryStyle(data['categoria']);
                        return _buildResultCard(docs[i].id, data, style);
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final style =
                            AppTheme.getCategoryStyle(data['categoria']);
                        return _buildResultListTile(
                            docs[i].id, data, style);
                      },
                    ),
            ),
            // ── Ver más ───────────────────────────────────────────
            if (rawCount >= _pageLimit)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _pageLimit += 30),
                    icon: const Icon(Iconsax.arrow_down,
                        color: AppTheme.primary),
                    label: Text('Ver más productos',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.radiusM),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.76,
      ),
      itemCount: 6,
      itemBuilder: (ctx, i) => const ShimmerProductCard(
        width: double.infinity,
        height: 220,
      ),
    );
  }

  Widget _buildResultCard(String productId, Map<String, dynamic> data,
      Map<String, dynamic> style) {
    final nombre = data['nombre'] ?? 'Producto';
    final vendedor = data['vendedor'] ?? 'Comerciante';
    final precio = data['precio'];
    final unidad = data['unidad'] ?? 'c/u';
    final stock = (data['stock'] ?? 1) as int;
    final precioStr =
        precio != null ? '\$${precio.toString()}' : 'Consultar';
    final ratingAvg = (data['ratingAvg'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
    final precioOriginal = (data['precioOriginal'] as num?)?.toDouble();
    final precioNum = (precio as num?)?.toDouble() ?? 0;
    final descPct = (precioOriginal != null && precioOriginal > precioNum && precioNum > 0)
        ? (((precioOriginal - precioNum) / precioOriginal) * 100).round()
        : 0;
    final fechaCreacion = data['fechaCreacion'] as Timestamp?;
    final isNew = fechaCreacion != null &&
        DateTime.now().difference(fechaCreacion.toDate()).inDays < 7;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(
          ProductDetailScreen(productId: productId, productData: data),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusL,
          boxShadow: AppTheme.shadowSm,
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: data['imagenUrl'] != null
                    ? CachedNetworkImage(
                        imageUrl: data['imagenUrl'] as String,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          color: style['color'] as Color,
                          child: Center(
                            child: Icon(style['icon'] as IconData,
                                color: (style['accent'] as Color)
                                    .withValues(alpha: 0.35),
                                size: 40),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: style['color'] as Color,
                          child: Center(
                            child: Icon(style['icon'] as IconData,
                                color: style['accent'] as Color, size: 48),
                          ),
                        ),
                      )
                    : Container(
                        color: style['color'] as Color,
                        child: Center(
                          child: Icon(style['icon'] as IconData,
                              color: style['accent'] as Color, size: 48),
                        ),
                      ),
              ),
              if (isNew && stock > 5)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      borderRadius: AppTheme.radiusFull,
                    ),
                    child: Text('Nuevo',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              if (stock == 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: AppTheme.radiusFull,
                    ),
                    child: Text('Agotado',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              if (stock > 0 && stock <= 5)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      borderRadius: AppTheme.radiusFull,
                    ),
                    child: Text('Últimas $stock',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.surface)),
                  ),
                ),
              // Botón favorito
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    if (_user == null) return;
                    final isFav = _favorites.contains(productId);
                    _firestoreService.toggleFavorite(
                        _user!.uid, productId, isFav);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Icon(
                      _favorites.contains(productId)
                          ? Iconsax.heart5
                          : Iconsax.heart,
                      color: _favorites.contains(productId)
                          ? Colors.red
                          : AppTheme.textMuted,
                      size: 15,
                    ),
                  ),
                ),
              ),
              // Rating badge
              if (ratingCount > 0)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: AppTheme.radiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.star5,
                            color: AppTheme.surface, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          ratingAvg.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              // Discount badge
              if (descPct > 0)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppTheme.radiusFull,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99DC2626),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text('-$descPct%',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              const SizedBox(height: 7),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (descPct > 0) ...[
                            Text(
                              '\$${precioOriginal!.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          ],
                          Text(precioStr,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary)),
                          Text(unidad, style: AppTheme.caption),
                        ]),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: AppTheme.orangeGradient,
                        borderRadius: AppTheme.radiusS,
                        boxShadow: [
                          BoxShadow(
                              color:
                                  AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Iconsax.arrow_right,
                          color: Colors.white, size: 16),
                    ),
                  ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildResultListTile(String productId, Map<String, dynamic> data,
      Map<String, dynamic> style) {
    final nombre = data['nombre'] ?? 'Producto';
    final vendedor = data['vendedor'] ?? 'Comerciante';
    final precio = (data['precio'] as num?)?.toDouble();
    final unidad = data['unidad'] ?? 'c/u';
    final stock = (data['stock'] ?? 1) as int;
    final municipio = data['municipio'] as String?;
    final precioStr = precio != null
        ? '\$${precio % 1 == 0 ? precio.toInt() : precio.toStringAsFixed(2)}'
        : 'Consultar';
    final precioOriginalList = (data['precioOriginal'] as num?)?.toDouble();
    final descPctList = (precioOriginalList != null &&
            precioOriginalList > (precio ?? 0) &&
            (precio ?? 0) > 0)
        ? (((precioOriginalList - precio!) / precioOriginalList) * 100).round()
        : 0;
    final imgUrl = data['imagenUrl'] as String?;
    final fechaCreacionList = data['fechaCreacion'] as Timestamp?;
    final isNewList = fechaCreacionList != null &&
        DateTime.now().difference(fechaCreacionList.toDate()).inDays < 7;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(
            ProductDetailScreen(productId: productId, productData: data)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusL,
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 88,
                height: 88,
                child: imgUrl != null && imgUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: style['color'] as Color,
                          child: Icon(style['icon'] as IconData,
                              color: style['accent'] as Color, size: 30),
                        ),
                      )
                    : Container(
                        color: style['color'] as Color,
                        child: Center(
                          child: Icon(style['icon'] as IconData,
                              color: style['accent'] as Color, size: 30),
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(nombre,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isNewList && stock > 5) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.green,
                            borderRadius: AppTheme.radiusFull,
                          ),
                          child: Text('Nuevo',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(vendedor,
                        style: AppTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (municipio != null) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Iconsax.location,
                            size: 10, color: AppTheme.textMuted),
                        const SizedBox(width: 2),
                        Text(municipio,
                            style: AppTheme.caption
                                .copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (descPctList > 0) ...[
                              Row(children: [
                                Text(
                                  '\$${precioOriginalList!.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                      decoration: TextDecoration.lineThrough),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: AppTheme.radiusFull,
                                    boxShadow: const [BoxShadow(color: Color(0x99DC2626), blurRadius: 6, offset: Offset(0, 2))],
                                  ),
                                  child: Text('-$descPctList%',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                              ]),
                            ],
                            Text('$precioStr/$unidad',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary)),
                          ],
                        ),
                        if (stock == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: AppTheme.radiusFull,
                            ),
                            child: Text('Agotado',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.surface)),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              if (_user == null) return;
                              final isFav = _favorites.contains(productId);
                              _firestoreService.toggleFavorite(
                                  _user!.uid, productId, isFav);
                            },
                            child: Icon(
                              _favorites.contains(productId)
                                  ? Iconsax.heart5
                                  : Iconsax.heart,
                              color: _favorites.contains(productId)
                                  ? Colors.red
                                  : AppTheme.textMuted,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Iconsax.arrow_right,
                color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
