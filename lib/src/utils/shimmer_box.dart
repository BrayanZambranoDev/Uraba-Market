import 'package:flutter/material.dart';

/// Widget de shimmer animado sin dependencias externas.
/// Uso: ShimmerBox(height: 120, borderRadius: AppTheme.radiusL)
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: Color.lerp(
            const Color(0xFFE2E8F0),
            const Color(0xFFF8FAFC),
            _anim.value,
          ),
        ),
      ),
    );
  }
}

/// Fila de shimmer: avatar circular + dos líneas de texto
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ShimmerBox(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 13, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                ShimmerBox(
                    width: 140,
                    height: 11,
                    borderRadius: BorderRadius.circular(6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de producto skeleton (igual tamaño que las reales)
class ShimmerProductCard extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerProductCard({
    super.key,
    this.width = 160,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
              height: height * 0.55,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16))),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                    height: 12, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                ShimmerBox(
                    width: 80,
                    height: 10,
                    borderRadius: BorderRadius.circular(5)),
                const SizedBox(height: 8),
                ShimmerBox(
                    width: 60,
                    height: 14,
                    borderRadius: BorderRadius.circular(6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de publicación (feed) skeleton
class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + role
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                ShimmerBox(
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                          height: 13,
                          borderRadius: BorderRadius.circular(6)),
                      const SizedBox(height: 6),
                      ShimmerBox(
                          width: 90,
                          height: 10,
                          borderRadius: BorderRadius.circular(5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Text lines
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 12, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                ShimmerBox(height: 12, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                ShimmerBox(
                    width: 200,
                    height: 12,
                    borderRadius: BorderRadius.circular(6)),
              ],
            ),
          ),
          // Image placeholder
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: ShimmerBox(
                height: 180,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )),
          ),
          // Actions bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                ShimmerBox(
                    width: 70,
                    height: 10,
                    borderRadius: BorderRadius.circular(5)),
                const SizedBox(width: 16),
                ShimmerBox(
                    width: 90,
                    height: 10,
                    borderRadius: BorderRadius.circular(5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
