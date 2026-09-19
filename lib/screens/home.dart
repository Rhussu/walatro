import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:walatro/screens/lobby.dart';
import 'package:walatro/screens/setting.dart';
import 'package:walatro/screens/table_scorekeeper_screen.dart';
import 'package:walatro/widgets/hypnotic_background.dart';
import 'package:walatro/widgets/retro_ui.dart';
import 'package:walatro/widgets/rules_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Animación suave de levitación y pulso para el logo y elementos decorativos
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _navigateToLobby() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LobbyScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingScreen()),
    );
  }

  void _navigateToTableScorekeeper() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TableScorekeeperScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: HypnoticBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatOffset =
                  math.sin(_floatController.value * math.pi) * 8.0;
              final pulseScale =
                  1.0 + math.sin(_floatController.value * math.pi) * 0.02;

              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Espacio superior para balance
                        const SizedBox(height: 10),

                        // LOGO RETRO "WALATRO" CON ANIMACIÓN DE FLOTACIÓN
                        Transform.translate(
                          offset: Offset(0, -floatOffset),
                          child: Transform.scale(
                            scale: pulseScale,
                            child: _buildTitleLogo(),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // CARTAS DECORATIVAS EN ABANICO ESTILO BALATRO
                        Transform.translate(
                          offset: Offset(0, floatOffset * 0.6),
                          child: _buildFannedCards(),
                        ),

                        const SizedBox(height: 36),

                        // MENÚ PRINCIPAL DE BOTONES RETRO
                        RetroButton(
                          color: const Color(0xFF00C853), // Verde arcade
                          onPressed: _navigateToLobby,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'JUGAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  fontFamily: 'Courier',
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        RetroButton(
                          color: const Color(0xFF00B4D8), // Cian / azul vibrante arcade
                          onPressed: _navigateToTableScorekeeper,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ANOTADOR DE MESA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  fontFamily: 'Courier',
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        RetroButton(
                          color: const Color(
                            0xFFFF9100,
                          ), // Ámbar / naranja arcade
                          onPressed: () => RulesDialog.show(context),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'CÓMO JUGAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  fontFamily: 'Courier',
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        RetroButton(
                          color: const Color(
                            0xFF3F37C9,
                          ), // Azul/índigo profundo
                          onPressed: _navigateToSettings,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'AJUSTES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  fontFamily: 'Courier',
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // PIE DE PÁGINA DISCRETO CON VERSIÓN Y CRÉDITOS
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Logo retro 3D "WALATRO" con efecto multicapa de sombra dura y resplandor
  Widget _buildTitleLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contenedor del título con borde retro
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24).withAlpha(220),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(6, 6)),
            ],
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 46,
                letterSpacing: 4,
                shadows: [Shadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              children: [
                TextSpan(
                  text: 'WA',
                  style: TextStyle(color: Color(0xFF00F0FF)), // Cian eléctrico
                ),
                TextSpan(
                  text: 'LA',
                  style: TextStyle(color: Color(0xFFFFDE59)), // Amarillo arcade
                ),
                TextSpan(
                  text: 'TRO',
                  style: TextStyle(color: Color(0xFFFF3366)), // Rojo carmesí
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Subtítulo con palos de póker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            border: Border.all(color: const Color(0xFFFFDE59), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '♠  A gambling memory game  ♣',
            style: TextStyle(
              color: Color(0xFFFFDE59),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  /// 3 cartas retro en abanico decorativo
  Widget _buildFannedCards() {
    return SizedBox(
      height: 124,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Carta izquierda: As de Picas
            Transform.translate(
              offset: const Offset(-52, 6),
              child: Transform.rotate(
                angle: -0.22,
                child: _buildMiniCard('A', '♥', const Color(0xFFE63946)),
              ),
            ),
            // Carta derecha: Rey de Corazones
            Transform.translate(
              offset: const Offset(52, 6),
              child: Transform.rotate(angle: 0.22, child: _buildJokerCard()),
            ),
            // Carta central: Joker comodín
            Transform.translate(
              offset: const Offset(0, -6),

              child: _buildMiniCard('K', '♠', Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  /// Mini carta de póker con diseño retro
  Widget _buildMiniCard(String rank, String suit, Color color) {
    return Container(
      width: 72,
      height: 106,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, offset: Offset(4, 4), blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              rank,
              style: TextStyle(
                color: color,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 14,
                height: 1,
              ),
            ),
          ),
          Text(suit, style: TextStyle(color: color, fontSize: 24, height: 1)),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              rank,
              style: TextStyle(
                color: color,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 14,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carta de Joker decorativa para el centro del abanico
  Widget _buildJokerCard() {
    return Container(
      width: 78,
      height: 114,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF275), // Fondo dorado suave de comodín
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD90429), width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Align(
            alignment: Alignment.topLeft,
            child: Text(
              '★',
              style: TextStyle(
                color: Color(0xFFD90429),
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 12,
                height: 1,
              ),
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🃏', style: TextStyle(fontSize: 22, height: 1.1)),
              Text(
                'JOKER',
                style: TextStyle(
                  color: Color(0xFF2B2D42),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                  letterSpacing: 1,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '★',
              style: TextStyle(
                color: Color(0xFFD90429),
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 12,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pie de página con versión e información
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(140),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'v0.1.0 • WALATRO EDITION',
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'Courier',
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
