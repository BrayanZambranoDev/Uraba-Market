import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'theme/app_theme.dart';
import 'nueva_publicacion_screen.dart';
import 'utils/shimmer_box.dart';
import 'package:iconsax/iconsax.dart';

// Gradientes de fondo (sincronizado con nueva_publicacion_screen.dart)
const List<List<Color>> kPostBgGradients = [
  [Color(0xFF1C3320), Color(0xFFEF4444)],
  [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
  [Color(0xFF10B981), Color(0xFF3B82F6)],
  [Color(0xFFF59E0B), Color(0xFF10B981)],
  [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  [Color(0xFF0F172A), Color(0xFF1E293B)],
];

const _kBg   = Color(0xFF0A0F0A);
const _kCard = Color(0xFF131C13);

// ─── Feed Screen ──────────────────────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final user = FirebaseAuth.instance.currentUser;
  late final Stream<QuerySnapshot> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = FirebaseFirestore.instance
        .collection('publicaciones')
        .orderBy('fechaCreacion', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Llamado desde HomeScreen cuando el usuario toca el tab Feed estando ya en él
  void scrollToTop() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async =>
            await Future.delayed(const Duration(milliseconds: 300)),
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: _kBg,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              toolbarHeight: 64,
              flexibleSpace: Container(color: _kBg),
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Row(children: [
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.arrow_left,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset('imagen conversaciones.png',
                    width: 32, height: 32, fit: BoxFit.contain),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Urabá Stories',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text('Comparte lo mejor de tu tierra 🌿',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.55)),
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
              actions: [
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      AppTheme.pageRoute(const NuevaPublicacionScreen())),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: AppTheme.radiusFull,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Iconsax.add, color: Colors.white, size: 15),
                      const SizedBox(width: 4),
                      Text('Publicar',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(Iconsax.notification,
                      color: Colors.white.withValues(alpha: 0.85), size: 24),
                ),
              ],
            ),

            // ── Stories bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _StoriesBar(currentUser: user),
            ),

            // ── Category chips ───────────────────────────────────
            SliverToBoxAdapter(
              child: _CategoryChips(),
            ),

            // ── Posts ────────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (_, i) => const ShimmerPostCard(),
                        childCount: 3),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text('Error al cargar publicaciones',
                          style: AppTheme.bodyMuted),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(
                      onPublish: () => Navigator.push(context,
                          AppTheme.pageRoute(const NuevaPublicacionScreen())),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == docs.length) {
                        return const SizedBox(height: 120);
                      }
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _PostCard(
                          key: ValueKey(doc.id),
                          doc: doc,
                          data: data,
                          currentUser: user);
                    },
                    childCount: docs.length + 1,
                    findChildIndexCallback: (key) {
                      final id = (key as ValueKey<String>).value;
                      final idx = docs.indexWhere((d) => d.id == id);
                      return idx == -1 ? null : idx;
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Chips ───────────────────────────────────────────────────────────
class _CategoryChips extends StatefulWidget {
  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  int _selected = 0;
  static const _cats = [
    (Iconsax.element_3, 'Todas'),
    (Iconsax.tree, 'Agricultura'),
    (Iconsax.tree, 'Naturaleza'),
    (Iconsax.people, 'Comunidad'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (int i = 0; i < _cats.length; i++) ...[
                GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _selected == i
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_cats[i].$1,
                          size: 13,
                          color: _selected == i ? Colors.white : Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 5),
                      Text(_cats[i].$2,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selected == i ? Colors.white : Colors.white.withValues(alpha: 0.6))),
                    ]),
                  ),
                ),
                if (i < _cats.length - 1) const SizedBox(width: 8),
              ],
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Iconsax.setting_4, color: Colors.white.withValues(alpha: 0.6), size: 20),
      ]),
    );
  }
}

// ─── Stories Bar ──────────────────────────────────────────────────────────────
class _StoriesBar extends StatefulWidget {
  final User? currentUser;
  const _StoriesBar({this.currentUser});

  @override
  State<_StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<_StoriesBar> {
  late final Stream<QuerySnapshot> _storiesStream;

  @override
  void initState() {
    super.initState();
    _storiesStream = FirebaseFirestore.instance
        .collection('publicaciones')
        .orderBy('fechaCreacion', descending: true)
        .limit(30)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _storiesStream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              // Dedup por autorId (historia por usuario)
              final seen = <String>{};
              final stories = <Map<String, dynamic>>[];
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final autorId = data['autorId'] as String? ?? '';
                if (!seen.contains(autorId)) {
                  seen.add(autorId);
                  stories.add({'id': doc.id, ...data});
                }
                if (stories.length >= 8) break;
              }

              return SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return _MyStoryItem(currentUser: widget.currentUser);
                    }
                    final story = stories[i - 1];
                    return _StoryItem(
                      key: ValueKey(story['autorId'] as String? ?? story['id']),
                      story: story,
                      onTap: () => _openStory(ctx, story),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openStory(BuildContext context, Map<String, dynamic> story) {
    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (ctx, _, __) => _StoryViewer(story: story),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ));
  }
}

class _MyStoryItem extends StatelessWidget {
  final User? currentUser;
  const _MyStoryItem({this.currentUser});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, AppTheme.pageRoute(const NuevaPublicacionScreen())),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              // Anillo gradiente verde
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF72C46A), Color(0xFF2D9E4E), Color(0xFF0E7C5A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0F1A10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: currentUser?.photoURL != null
                      ? CachedNetworkImage(
                          imageUrl: currentUser!.photoURL!,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero)
                      : Icon(Iconsax.user,
                          color: Colors.white.withValues(alpha: 0.5), size: 34),
                ),
              ),
              // Botón +
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF72C46A), Color(0xFF3D8A38)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0F0A), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]),
                  child: const Icon(Iconsax.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text('Tu historia',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback onTap;
  const _StoryItem({super.key, required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nombre = story['autorNombre'] as String? ?? 'Usuario';
    final foto = story['autorFoto'] as String?;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
    final tipo = story['tipo'] as String? ?? 'normal';

    // Color del anillo según tipo de publicación
    final ringColors = tipo == 'oferta'
        ? const [Color(0xFFDC2626), Color(0xFFEF4444)]
        : tipo == 'evento'
            ? const [Color(0xFF2563EB), Color(0xFF7C3AED)]
            : const [Color(0xFFEC4899), Color(0xFFF97316), Color(0xFF8B5CF6)];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: ringColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: ringColors.first.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF0F1A10)),
              clipBehavior: Clip.antiAlias,
              child: foto != null
                  ? CachedNetworkImage(
                      imageUrl: foto,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero)
                  : Container(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      child: Center(
                          child: Text(inicial,
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: AppTheme.primary))),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(nombre.split(' ').first,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─── Story Viewer (fullscreen) ────────────────────────────────────────────────
class _StoryViewer extends StatefulWidget {
  final Map<String, dynamic> story;
  const _StoryViewer({required this.story});

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _prog;

  List<String> get _images {
    final urls = List<String>.from(
        widget.story['imagenURLs'] as List? ?? []);
    if (urls.isEmpty) {
      final url = widget.story['imagenURL'] as String?;
      if (url != null) urls.add(url);
    }
    return urls;
  }

  @override
  void initState() {
    super.initState();
    _prog = AnimationController(
        vsync: this,
        duration: Duration(seconds: _images.isNotEmpty ? 6 : 4))
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          Navigator.pop(context);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _prog.dispose();
    super.dispose();
  }

  String _timeAgo(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.story['autorNombre'] as String? ?? 'Usuario';
    final foto = widget.story['autorFoto'] as String?;
    final texto = widget.story['texto'] as String? ?? '';
    final ubicacion = widget.story['ubicacion'] as String?;
    final bgIndex = widget.story['bgIndex'] as int?;
    final ts = widget.story['fechaCreacion'] as Timestamp?;
    final images = _images;

    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Contenido principal ────────────────────────────────
            if (images.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: images[0],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.black),
                  errorWidget: (_, __, ___) => Container(color: Colors.black),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: bgIndex != null
                        ? LinearGradient(
                            colors: kPostBgGradients[bgIndex],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : const LinearGradient(
                            colors: [Color(0xFF0F1A10), Color(0xFF1C3320)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(texto,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.4),
                      textAlign: TextAlign.center),
                ),
              ),

            // ── Gradiente superior (legibilidad header) ────────────
            Positioned(
              top: 0, left: 0, right: 0,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Gradiente inferior (legibilidad texto) ─────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 180,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Barra de progreso ──────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              right: 12,
              child: ClipRRect(
                borderRadius: AppTheme.radiusFull,
                child: LinearProgressIndicator(
                  value: _prog.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  color: Colors.white,
                  minHeight: 4,
                ),
              ),
            ),

            // ── Header usuario ─────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Avatar con anillo
                  Container(
                    width: 46, height: 46,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF72C46A), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0A0F0A),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: foto != null
                          ? CachedNetworkImage(
                              imageUrl: foto,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero)
                          : Container(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              child: Center(
                                  child: Text(inicial,
                                      style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16)))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ])),
                        if (ts != null)
                          Text(_timeAgo(ts),
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.close_circle,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Texto sobre imagen ─────────────────────────────────
            if (images.isNotEmpty && texto.isNotEmpty)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: AppTheme.radiusL,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(texto,
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4)),
                ),
              ),

            // ── Ubicación ──────────────────────────────────────────
            if (ubicacion != null && ubicacion.isNotEmpty)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom +
                    (images.isNotEmpty && texto.isNotEmpty ? 100 : 28),
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: AppTheme.radiusFull,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.location,
                          size: 13, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Text(ubicacion,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onPublish;
  const _EmptyState({required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.document_text,
                  size: 42, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Sin publicaciones aún', style: AppTheme.heading3),
            const SizedBox(height: 8),
            Text(
              'Sé el primero en compartir tu ubicación o lo que tienes disponible hoy',
              style: AppTheme.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusM),
                elevation: 0,
              ),
              onPressed: onPublish,
              icon: const Icon(Iconsax.add, size: 20),
              label: Text('Crear publicación',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final User? currentUser;

  const _PostCard(
      {super.key,
      required this.doc,
      required this.data,
      required this.currentUser});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  int _imagePage = 0;
  bool _expanded = false;
  bool _showHeart = false;
  late AnimationController _heartCtrl;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _heartCtrl.reset();
          if (mounted) setState(() => _showHeart = false);
        }
      });
    _heartAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    final d = ts.toDate();
    return '${d.day}/${d.month}';
  }

  void _toggleLike(List<String> currentLikes) {
    if (widget.currentUser == null) return;
    final uid = widget.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(widget.doc.id);
    if (currentLikes.contains(uid)) {
      ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  void _doubleTapLike(List<String> likes) {
    HapticFeedback.mediumImpact();
    if (widget.currentUser != null &&
        !likes.contains(widget.currentUser!.uid)) {
      _toggleLike(likes);
    }
    setState(() => _showHeart = true);
    _heartCtrl.forward();
  }

  void _share(String texto, String autorNombre) {
    final text =
        '$autorNombre en Urabá Market:\n$texto\n\nDescargala en urab.market';
    Share.share(text);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        title: Text('Eliminar publicación', style: AppTheme.heading3),
        content: Text('¿Deseas eliminar esta publicación?',
            style: AppTheme.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600))),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('publicaciones')
                  .doc(widget.doc.id)
                  .delete();
              Navigator.pop(ctx);
            },
            child: Text('Eliminar',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
          docId: widget.doc.id, currentUser: widget.currentUser),
    );
  }

  void _showEditSheet(String currentText) {
    final ctrl = TextEditingController(text: currentText);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: AppTheme.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Editar publicación', style: AppTheme.heading3),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 5,
                minLines: 3,
                autofocus: true,
                style: AppTheme.body,
                decoration: InputDecoration(
                  hintText: '¿Qué quieres compartir?',
                  hintStyle: AppTheme.bodyMuted,
                  filled: true,
                  fillColor: AppTheme.bg,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.radiusM,
                    borderSide:
                        const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.radiusM,
                    borderSide:
                        const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.radiusM,
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusM),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final newText = ctrl.text.trim();
                    if (newText.isNotEmpty) {
                      FirebaseFirestore.instance
                          .collection('publicaciones')
                          .doc(widget.doc.id)
                          .update({'texto': newText});
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text('Guardar cambios',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipoBadge(String tipo) {
    const badges = {
      'oferta': (
        Iconsax.discount_circle,
        [Color(0xFFDC2626), Color(0xFFB91C1C)],
      ),
      'pregunta': (
        Iconsax.info_circle,
        [Color(0xFF16A34A), Color(0xFF15803D)],
      ),
      'evento': (
        Iconsax.location,
        [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      ),
    };
    final b = badges[tipo];
    if (b == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: b.$2,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.radiusFull,
        boxShadow: [
          BoxShadow(
            color: b.$2.first.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(b.$1, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${tipo[0].toUpperCase()}${tipo.substring(1)}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final autorNombre = data['autorNombre'] as String? ?? 'Usuario';
    final autorFoto = data['autorFoto'] as String?;
    final autorRol = data['autorRol'] as String? ?? '';
    final texto = data['texto'] as String? ?? '';
    final ubicacion = data['ubicacion'] as String?;
    final imagenURLs =
        List<String>.from(data['imagenURLs'] as List? ?? []);
    if (imagenURLs.isEmpty && data['imagenURL'] != null) {
      imagenURLs.add(data['imagenURL'] as String);
    }
    final likes = List<String>.from(data['likes'] ?? []);
    final comentariosCount = data['comentariosCount'] as int? ?? 0;
    final fechaCreacion = data['fechaCreacion'] as Timestamp?;
    final isLiked = widget.currentUser != null &&
        likes.contains(widget.currentUser!.uid);
    final isOwner =
        widget.currentUser?.uid == data['autorId'];
    final tipo = data['tipo'] as String? ?? 'normal';
    final bgIndex = data['bgIndex'] as int?;
    final hasImages = imagenURLs.isNotEmpty;
    final inicial =
        autorNombre.isNotEmpty ? autorNombre[0].toUpperCase() : 'U';

    // Formatear conteo de likes
    final likesText = likes.length == 1
        ? 'A 1 persona le gusta esto'
        : 'A ${likes.length} personas les gusta esto';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: AppTheme.radiusL,
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 6, 0),
                child: Row(
                  children: [
                    // Avatar con borde de color por rol
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: autorRol == 'Comerciante' || autorRol == 'Productor'
                            ? const LinearGradient(
                                colors: [Color(0xFF72C46A), Color(0xFF3D8A38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)
                            : const LinearGradient(
                                colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF2D5035), Color(0xFF1C3320)],
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: autorFoto != null
                            ? CachedNetworkImage(
                                imageUrl: autorFoto,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                errorWidget: (c, u, e) => Center(
                                    child: Text(inicial,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontSize: 17))))
                            : Center(
                                child: Text(inicial,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: 17)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(autorNombre,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                        color: Colors.white),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              // Verified badge para comerciantes/productores
                              if (autorRol == 'Comerciante' || autorRol == 'Productor') ...[
                                const SizedBox(width: 5),
                                Container(
                                  width: 17,
                                  height: 17,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1D9BF0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Iconsax.check,
                                      color: Colors.white, size: 11),
                                ),
                              ],
                              if (tipo != 'normal') ...[
                                const SizedBox(width: 6),
                                _tipoBadge(tipo),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (autorRol.isNotEmpty) ...[
                                Text(autorRol,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.5))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.circle, size: 3, color: Colors.white.withValues(alpha: 0.5)),
                                ),
                              ],
                              Text(_timeAgo(fechaCreacion),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.5))),
                              const SizedBox(width: 4),
                              Icon(Iconsax.global,
                                  size: 12, color: Colors.white.withValues(alpha: 0.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menu 3 dots
                    PopupMenuButton<String>(
                      icon: Icon(Iconsax.more,
                          size: 22, color: Colors.white.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.radiusL),
                      onSelected: (val) {
                        if (val == 'edit') _showEditSheet(texto);
                        if (val == 'delete') _confirmDelete(context);
                        if (val == 'share') _share(texto, autorNombre);
                      },
                      itemBuilder: (_) => [
                        if (isOwner) ...[
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Iconsax.edit,
                                  size: 18, color: Colors.white.withValues(alpha: 0.65)),
                              const SizedBox(width: 10),
                              Text('Editar', style: AppTheme.body),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Iconsax.trash,
                                  size: 18, color: AppTheme.error),
                              const SizedBox(width: 10),
                              Text('Eliminar',
                                  style: AppTheme.body.copyWith(color: AppTheme.error)),
                            ]),
                          ),
                        ],
                        PopupMenuItem(
                          value: 'share',
                          child: Row(children: [
                            Icon(Iconsax.share,
                                size: 18, color: Colors.white.withValues(alpha: 0.65)),
                            const SizedBox(width: 10),
                            Text('Compartir', style: AppTheme.body),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Ubicación (estilo Facebook) ────────────────────────
              if (ubicacion != null && ubicacion.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.location,
                          size: 13, color: AppTheme.primary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(ubicacion,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primary)),
                      ),
                    ],
                  ),
                ),

              // ── Texto ──────────────────────────────────────────────
              if (texto.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, hasImages ? 10 : 10, 16, hasImages ? 0 : 4),
                  child: !hasImages && bgIndex != null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: kPostBgGradients[bgIndex],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: AppTheme.radiusL,
                          ),
                          child: Text(texto,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.4),
                              textAlign: TextAlign.center),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _expanded
                                  ? texto
                                  : (texto.length > 200
                                      ? '${texto.substring(0, 200)}...'
                                      : texto),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  height: 1.4),
                            ),
                            if (texto.length > 200 && !_expanded)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _expanded = true),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('Ver m\u00e1s',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.5))),
                                ),
                              ),
                          ],
                        ),
                ),

              // ── Carrusel de imagenes (FULL-BLEED) ──────────────────
              if (hasImages) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onDoubleTap: () => _doubleTapLike(likes),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 340,
                          child: PageView.builder(
                            itemCount: imagenURLs.length,
                            onPageChanged: (p) =>
                                setState(() => _imagePage = p),
                            itemBuilder: (ctx, i) => RepaintBoundary(
                              child: CachedNetworkImage(
                                imageUrl: imagenURLs[i],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholder: (c, u) => Container(
                                  color: const Color(0xFF1A2A1A),
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          color: AppTheme.primary,
                                          strokeWidth: 2)),
                                ),
                                errorWidget: (c, u, e) =>
                                    Container(color: const Color(0xFF1A2A1A)),
                              ),
                            ),
                          ),
                        ),
                        // Dots de pagina (pill style)
                        if (imagenURLs.length > 1)
                          Positioned(
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: AppTheme.radiusFull,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  imagenURLs.length,
                                  (i) => AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    width: _imagePage == i ? 20 : 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: _imagePage == i
                                          ? Colors.white
                                          : Colors.white38,
                                      borderRadius: AppTheme.radiusFull,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Contador (top right)
                        if (imagenURLs.length > 1)
                          Positioned(
                            top: 12,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: AppTheme.radiusFull),
                              child: Text(
                                  '${_imagePage + 1}/${imagenURLs.length}',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        // Heart animation
                        if (_showHeart)
                          ScaleTransition(
                            scale: _heartAnim,
                            child: Icon(Iconsax.heart5,
                                color: Colors.white.withValues(alpha: 0.95),
                                size: 100),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Resumen de likes (estilo Facebook) ─────────────────
              if (likes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      // Mini iconos de reacciones
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                          ),
                        ),
                        child: const Icon(Iconsax.heart5,
                            color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(likesText,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.5))),
                      ),
                      if (comentariosCount > 0)
                        Text('$comentariosCount comentarios',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Divisor
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),

              // ── Barra de acciones (3 columnas iguales) ─────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: isLiked ? Iconsax.heart5 : Iconsax.heart,
                        label: 'Me gusta',
                        color: isLiked ? const Color(0xFFEE5A24) : AppTheme.textMuted,
                        active: isLiked,
                        onTap: () => _toggleLike(likes),
                      ),
                    ),
                    Expanded(
                      child: _ActionBtn(
                        icon: Iconsax.message,
                        label: 'Comentar',
                        color: Colors.white.withValues(alpha: 0.5),
                        onTap: _openComments,
                      ),
                    ),
                    Expanded(
                      child: _ActionBtn(
                        icon: Iconsax.share,
                        label: 'Compartir',
                        color: Colors.white.withValues(alpha: 0.5),
                        onTap: () => _share(texto, autorNombre),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// ─── Action Button (centrado, estilo Facebook) ──────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool active;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Comments Bottom Sheet ────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String docId;
  final User? currentUser;

  const _CommentsSheet(
      {required this.docId, required this.currentUser});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.currentUser == null) return;

    setState(() => _sending = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser!.uid)
          .get();
      final userData = userDoc.data();

      final batch = FirebaseFirestore.instance.batch();

      final commentRef = FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(widget.docId)
          .collection('comentarios')
          .doc();

      batch.set(commentRef, {
        'autorId': widget.currentUser!.uid,
        'autorNombre': userData?['nombre'] ??
            userData?['displayName'] ??
            'Usuario',
        'autorFoto': userData?['photoURL'],
        'texto': text,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      batch.update(
        FirebaseFirestore.instance
            .collection('publicaciones')
            .doc(widget.docId),
        {'comentariosCount': FieldValue.increment(1)},
      );

      await batch.commit();
      _controller.clear();
    } catch (e) {
      debugPrint('Error sending comment: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: AppTheme.radiusFull,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Comentarios', style: AppTheme.heading3),
            ),
            const Divider(height: 1),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('publicaciones')
                    .doc(widget.docId)
                    .collection('comentarios')
                    .orderBy('fechaCreacion', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary, strokeWidth: 2));
                  }
                  final comentarios = snapshot.data?.docs ?? [];
                  if (comentarios.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.message,
                              size: 44, color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Text('Sin comentarios aún',
                              style: AppTheme.bodyMuted),
                          const SizedBox(height: 4),
                          Text('Sé el primero en comentar',
                              style: AppTheme.caption),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: comentarios.length,
                    itemBuilder: (ctx, i) {
                      final c = comentarios[i].data()
                          as Map<String, dynamic>;
                      final nombre =
                          c['autorNombre'] as String? ?? 'Usuario';
                      final foto = c['autorFoto'] as String?;
                      final texto = c['texto'] as String? ?? '';
                      final ts = c['fechaCreacion'] as Timestamp?;
                      final inicial = nombre.isNotEmpty
                          ? nombre[0].toUpperCase()
                          : 'U';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.orangeGradient,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: foto != null
                                  ? CachedNetworkImage(
                                      imageUrl: foto,
                                      fit: BoxFit.cover,
                                      errorWidget: (c, u, e) => Center(
                                          child: Text(inicial,
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Colors.white,
                                                      fontSize: 12))))
                                  : Center(
                                      child: Text(inicial,
                                          style:
                                              GoogleFonts.plusJakartaSans(
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bg,
                                      borderRadius: BorderRadius.only(
                                        topRight:
                                            const Radius.circular(16),
                                        bottomLeft:
                                            const Radius.circular(16),
                                        bottomRight:
                                            const Radius.circular(16),
                                        topLeft: i == 0
                                            ? Radius.zero
                                            : const Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(nombre,
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 12)),
                                        const SizedBox(height: 3),
                                        Text(texto,
                                            style: AppTheme.body),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, top: 4),
                                    child: Text(_timeAgo(ts),
                                        style: AppTheme.caption),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: AppTheme.body,
                        textCapitalization:
                            TextCapitalization.sentences,
                        onSubmitted: (_) => _sendComment(),
                        decoration: InputDecoration(
                          hintText: 'Escribe un comentario...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: AppTheme.bg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: AppTheme.radiusXL,
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppTheme.radiusXL,
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppTheme.radiusXL,
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _sending
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                                color: AppTheme.primary, strokeWidth: 2))
                        : GestureDetector(
                            onTap: _sendComment,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: AppTheme.orangeGradient,
                                shape: BoxShape.circle,
                                boxShadow:
                                    AppTheme.shadowOrangeList,
                              ),
                              child: const Icon(Iconsax.send_1,
                                  color: Colors.white, size: 18),
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
}
