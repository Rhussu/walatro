import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Un fondo procedural animado inspirado en la icónica estética hipnótica
/// de Balatro, con vórtices psicodélicos de color, palos de póker flotantes,
/// líneas de escaneo CRT y sombreado de viñeta.
class HypnoticBackground extends StatefulWidget {
  final Widget? child;
  final bool showScanlines;
  final bool showFloatingSuits;

  const HypnoticBackground({
    super.key,
    this.child,
    this.showScanlines = true,
    this.showFloatingSuits = true,
  });

  @override
  State<HypnoticBackground> createState() => _HypnoticBackgroundState();
}

class _HypnoticBackgroundState extends State<HypnoticBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Ciclo suave continuo de 18 segundos para animación relajante e hipnótica
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lienzo animado de vórtice y partículas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _HypnoticPainter(
                  progress: _controller.value,
                  showScanlines: widget.showScanlines,
                  showFloatingSuits: widget.showFloatingSuits,
                ),
              );
            },
          ),
        ),

        // Viñeta y atmósfera CRT estática encima del lienzo
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(90),
                    Colors.black.withAlpha(210),
                  ],
                  stops: const [0.45, 0.8, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Contenido de la pantalla
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _HypnoticPainter extends CustomPainter {
  final double progress;
  final bool showScanlines;
  final bool showFloatingSuits;

  _HypnoticPainter({
    required this.progress,
    required this.showScanlines,
    required this.showFloatingSuits,
  });

  // Semillas pseudo-aleatorias fijas para las partículas flotantes
  static final List<_SuitParticleSeed> _particles = List.generate(24, (i) {
    final random = math.Random(i * 1337 + 42);
    const suits = ['♠', '♥', '♦', '♣'];
    final suit = suits[i % suits.length];
    final isRed = suit == '♥' || suit == '♦';
    return _SuitParticleSeed(
      seedX: random.nextDouble(),
      seedY: random.nextDouble(),
      speedX: (random.nextDouble() - 0.5) * 0.035,
      speedY: -0.02 - random.nextDouble() * 0.045, // Deriva hacia arriba
      rotSpeed: (random.nextDouble() - 0.5) * 1.5,
      scale: 16.0 + random.nextDouble() * 22.0,
      opacity: 0.12 + random.nextDouble() * 0.22,
      suit: suit,
      color: isRed ? const Color(0xFFFF4D6D) : const Color(0xFF64DFDF),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 0.75;
    final time = progress * 2 * math.pi;

    // 1. Fondo base de gradiente oscuro estilo casino retro
    final baseRect = Offset.zero & size;
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF0F1423), // Azul noche profundo
        Color(0xFF071B1E), // Verde azulado oscuro
        Color(0xFF140A1A), // Púrpura oscuro
      ],
      stops: [
        0.0,
        0.5 + 0.2 * math.sin(time * 0.5),
        1.0,
      ],
    );
    canvas.drawRect(baseRect, Paint()..shader = baseGradient.createShader(baseRect));

    // 2. Ondas y anillos de vórtice hipnótico psicodélico
    final ringCount = 14;
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = ringCount; i >= 1; i--) {
      final ringNorm = i / ringCount;
      final radius = maxRadius * ringNorm;

      // Desplazamiento y ondulación de radio
      final waveOffset = math.sin(time + i * 0.6) * (18.0 + i * 2.0);
      final dynamicRadius = math.max(10.0, radius + waveOffset);

      // Rotación individual de cada anillo
      final ringAngle = time * (i % 2 == 0 ? 0.35 : -0.28) + (i * 0.4);

      // Grosor dinámico tipo resplandor arcade
      wavePaint.strokeWidth = 14.0 + math.sin(time * 1.2 + i) * 6.0 + (i * 1.8);

      // Colores psicodélicos alternantes inspirados en Balatro
      final color = _getVortexColor(i, ringCount, progress);
      wavePaint.color = color.withAlpha((45 + (1.0 - ringNorm) * 85).toInt());

      // Dibujar camino con pequeñas deformaciones orgánicas
      final path = Path();
      const points = 36;
      for (int p = 0; p <= points; p++) {
        final theta = (p / points) * 2 * math.pi + ringAngle;
        // Distorsión sinusoidal armónica
        final warp = math.sin(theta * 3 + time * 1.5) * (12.0 + i * 1.5) +
            math.cos(theta * 2 - time) * 8.0;
        final r = dynamicRadius + warp;
        final px = center.dx + r * math.cos(theta);
        final py = center.dy + r * math.sin(theta);

        if (p == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, wavePaint);
    }

    // 3. Foco de luz central pulsante (núcleo del vórtice)
    final coreRadius = 140.0 + math.sin(time * 2) * 25.0;
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withAlpha(60),
          const Color(0xFFFF007F).withAlpha(35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, corePaint);

    // 4. Palos de póker flotantes (♠, ♥, ♦, ♣)
    if (showFloatingSuits) {
      _drawFloatingSuits(canvas, size, progress);
    }

    // 5. Líneas de escaneo CRT sutiles
    if (showScanlines) {
      _drawCRTScanlines(canvas, size);
    }
  }

  Color _getVortexColor(int index, int total, double progress) {
    // Paleta de tonos retro Balatro: Carmesí, Cian, Ámbar, Azul eléctrico, Púrpura
    const palette = [
      Color(0xFFFF2A6D), // Fucsia/Carmesí neón
      Color(0xFF05D9E8), // Cian eléctrico
      Color(0xFFFFB703), // Oro arcade
      Color(0xFF7209B7), // Púrpura profundo
      Color(0xFF00F5D4), // Verde menta brillante
      Color(0xFF3F37C9), // Azul cobalto
    ];

    final cycle = (index + (progress * palette.length * 2).toInt()) % palette.length;
    return palette[cycle];
  }

  void _drawFloatingSuits(Canvas canvas, Size size, double progress) {
    final time = progress * 2 * math.pi;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];

      // Posición cíclica en el espacio
      double x = (p.seedX + progress * p.speedX * 8) % 1.0;
      if (x < 0) x += 1.0;
      double y = (p.seedY + progress * p.speedY * 8) % 1.0;
      if (y < 0) y += 1.0;

      final posX = x * size.width;
      final posY = y * size.height;

      // Ondulación suave
      final waveX = posX + math.sin(time + i) * 12.0;
      final waveY = posY + math.cos(time + i * 0.7) * 8.0;

      final rotation = p.rotSpeed * time;

      // Dibujar símbolo con TextPainter
      final span = TextSpan(
        text: p.suit,
        style: TextStyle(
          color: p.color.withAlpha((p.opacity * 255).toInt()),
          fontSize: p.scale,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(180),
              offset: const Offset(2, 2),
              blurRadius: 3,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(waveX, waveY);
      canvas.rotate(rotation);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  void _drawCRTScanlines(Canvas canvas, Size size) {
    final scanlinePaint = Paint()
      ..color = Colors.black.withAlpha(22)
      ..strokeWidth = 1.2;

    const step = 4.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HypnoticPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showScanlines != showScanlines ||
        oldDelegate.showFloatingSuits != showFloatingSuits;
  }
}

class _SuitParticleSeed {
  final double seedX;
  final double seedY;
  final double speedX;
  final double speedY;
  final double rotSpeed;
  final double scale;
  final double opacity;
  final String suit;
  final Color color;

  _SuitParticleSeed({
    required this.seedX,
    required this.seedY,
    required this.speedX,
    required this.speedY,
    required this.rotSpeed,
    required this.scale,
    required this.opacity,
    required this.suit,
    required this.color,
  });
}
