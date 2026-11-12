import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      image: 'assets/images/onboard_yuca.png',
      accent: Color(0xFFD4952A),
      bgGradient: [Color(0xFF0F1E12), Color(0xFF1C3320)],
      title: 'Productos frescos\ndel campo',
      subtitle:
          'Yuca, plátano, frutas y verduras directo del productor de Urabá a tu mesa.',
    ),
    _Slide(
      image: 'assets/images/onboard_india.png',
      accent: Color(0xFF72C46A),
      bgGradient: [Color(0xFF0A1F14), Color(0xFF0E4F35)],
      title: 'Artesanías locales\nhechas a mano',
      subtitle:
          'Apoya a los artesanos de la región y descubre piezas únicas con identidad propia.',
    ),
    _Slide(
      image: 'assets/images/onboard_ambulante.png',
      accent: Color(0xFFFFB59C),
      bgGradient: [Color(0xFF1A1406), Color(0xFF4D3A0A)],
      title: 'Comercio local\nal alcance de todos',
      subtitle:
          'Conecta con comerciantes y emprendedores de tu zona. Compra, vende y crece.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('uraba_onboarding_seen_2026', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;

    // Espacio reservado abajo para texto + dots + botón
    final bottomPanelHeight = 280.0 + bottomInset;
    // Imagen ocupa el resto
    final imageAreaHeight = screenH - bottomPanelHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF011713),
      body: Stack(
        children: [
          // Slide background completo
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              final slide = _slides[i];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: slide.bgGradient,
                  ),
                ),
                child: Stack(
                  children: [
                    // Glow radial detrás de la imagen
                    Positioned(
                      top: topInset + 20,
                      left: 0,
                      right: 0,
                      height: imageAreaHeight,
                      child: Center(
                        child: Container(
                          width: 480,
                          height: 480,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                slide.accent.withValues(alpha: 0.32),
                                slide.accent.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Imagen GRANDE — ocupa casi toda la pantalla arriba
                    Positioned(
                      top: topInset + 8,
                      left: 0,
                      right: 0,
                      height: imageAreaHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Image.asset(
                          slide.image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(Icons.image_outlined,
                                size: 100,
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Gradiente abajo para que el texto se lea sobre la imagen
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomPanelHeight + 40,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF011713).withValues(alpha: 0.65),
                      const Color(0xFF011713),
                    ],
                    stops: const [0.0, 0.35, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // Botón Omitir (top-right)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: Text('Omitir',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),

          // Panel inferior: título + subtítulo + dots + botón
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 0, 28, 24 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _slides[_currentPage].title,
                      key: ValueKey('title-$_currentPage'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtítulo
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _slides[_currentPage].subtitle,
                      key: ValueKey('sub-$_currentPage'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _slides[_currentPage].accent
                              : Colors.white.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _currentPage == i
                              ? [
                                  BoxShadow(
                                    color: _slides[_currentPage]
                                        .accent
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón principal
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: _slides[_currentPage]
                              .accent
                              .withValues(alpha: 0.40),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          _finish();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _slides[_currentPage].accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _slides.length - 1
                                ? 'Siguiente'
                                : 'Comenzar',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _slides[_currentPage].accent),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage < _slides.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_rounded,
                            size: 20,
                            color: _slides[_currentPage].accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String image;
  final Color accent;
  final List<Color> bgGradient;
  final String title;
  final String subtitle;

  const _Slide({
    required this.image,
    required this.accent,
    required this.bgGradient,
    required this.title,
    required this.subtitle,
  });
}
