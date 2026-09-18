import 'package:flutter/material.dart';
import 'package:walatro/widgets/retro_ui.dart';

class RulesDialog extends StatefulWidget {
  const RulesDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const RulesDialog(),
    );
  }

  @override
  State<RulesDialog> createState() => _RulesDialogState();
}

class _RulesDialogState extends State<RulesDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: RetroContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'REGLAS DE WALATRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white30, height: 20),

              // Pestañas
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.amberAccent,
                labelColor: Colors.amberAccent,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: 'PUNTOS'),
                  Tab(text: 'EL TURNO'),
                  Tab(text: 'PODERES'),
                  Tab(text: 'PARIDAD'),
                  Tab(text: 'FINAL'),
                ],
              ),
              const SizedBox(height: 12),

              // Contenido de las pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPuntosTab(),
                    _buildTurnoTab(),
                    _buildPoderesTab(),
                    _buildParidadTab(),
                    _buildFinalTab(),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botón cerrar
              RetroButton(
                text: 'ENTENDIDO',
                color: Colors.blueAccent.shade700,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPuntosTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleHeader('OBJETIVO: TENER MENOS PUNTOS'),
          _ruleText('El juego es de memoria. Cada jugador comienza con 4 cartas fijas boca abajo.'),
          _ruleText('Al inicio podrás memorizar las 2 cartas inferiores durante unos segundos.'),
          const SizedBox(height: 10),
          _ruleHeader('VALORES DE LAS CARTAS:'),
          _valueItem('A', '1 punto'),
          _valueItem('2 al 10', 'Su valor nominal (2 a 10 puntos)'),
          _valueItem('J, Q, K', '10 puntos'),
          _valueItem('K de Picas (K♠)', '-1 PUNTO (¡La mejor carta!)', highlight: true, color: Colors.purpleAccent),
          _valueItem('Jokers (★)', '0 PUNTOS', highlight: true, color: Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildTurnoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleHeader('EN TU TURNO:'),
          _ruleText('1. ANTES de robar: Puedes decidir cantar "Soy el que tiene menos cartas" si crees tener la menor suma.'),
          _ruleText('2. O Robar una carta:'),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ruleText('• Del MAZO DE ROBO (oculta para los demás).'),
                _ruleText('• Del DESCARTE: ¡Única condición! La carta NO debió ser quemada por paridad y nadie utilizó paridad sobre ella.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ruleText('3. Tras robar la carta, puedes:'),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ruleText('• CAMBIARLA por una de tus cartas (la tuya pasa al descarte).'),
                _ruleText('• BOTARLA directamente al mazo de descarte.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoderesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleHeader('PODERES ESPECIALES (7, 8 Y 9)'),
          _ruleText('Si la carta que botas es un 7, 8 o 9, puedes activar su poder:'),
          const SizedBox(height: 6),
          _powerItem('7', 'ESPIAR CARTA PROPIA', 'Puedes ver en secreto una de tus cartas.'),
          _powerItem('8', 'ESPIAR CARTA RIVAL', 'Puedes ver en secreto una carta de cualquier oponente.'),
          _powerItem('9', 'INTERCAMBIO', 'Intercambias una carta tuya con la de alguien más. ¡Puedes ver ambas cartas!'),
          const SizedBox(height: 10),
          _ruleHeader('REGLAS CLAVE DE LOS PODERES:'),
          _ruleText('• REGLA DE PODER ÚNICO: Aplica a los 3 poderes. Si una carta es recogida del descarte o quemada en paridad, YA NO puede volver a activar su poder.'),
          _ruleText('• OPCIONAL: Si lo prefieres, puedes pulsar "SALTAR PODER" y no usarlo.'),
        ],
      ),
    );
  }

  Widget _buildParidadTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleHeader('SISTEMA DE PARIDAD (QUEMAR CARTA)'),
          _ruleText('Al botar cualquier carta, cualquiera puede hacer "Paridad" botando una carta con el MISMO NÚMERO.'),
          _ruleText('• VENTANA ILIMITADA: Puedes cantar paridad en cualquier momento mientras esa carta siga arriba del descarte.'),
          _ruleText('• BOTÓN DE SEGURIDAD: Debes apretar primero el botón "PARIDAD" para armar el modo, y luego tocar la carta para evitar toques accidentales.'),
          _ruleText('• El servidor valida al primero que envíe la paridad.'),
          const SizedBox(height: 8),
          _ruleHeader('CON CARTA PROPIA:'),
          _ruleText('✔ Aciertas: Te quedas con 1 carta menos.'),
          _ruleText('✖ Fallas: Te quedas con tu carta + 1 de penalización (+1 carta).'),
          const SizedBox(height: 6),
          _ruleHeader('CON CARTA DE OTRO JUGADOR:'),
          _ruleText('✔ Aciertas: Se descarta la suya y tú le das una de tus cartas (tú quedas con -1).'),
          _ruleText('✖ Fallas: Tú te quedas con ambas cartas y el rival se beneficia con -1.'),
          const SizedBox(height: 6),
          _ruleText('🔥 QUEMADO: Toda carta en paridad se QUEMA y no puede usar poderes especiales.'),
        ],
      ),
    );
  }

  Widget _buildFinalTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleHeader('3 CASOS PARA TERMINAR LA RONDA:'),
          const SizedBox(height: 6),
          _caseBox(
            'CASO 1: LLAMADO VOLUNTARIO',
            'En tu turno, antes de robar, dices "Soy el que tiene menos cartas".\n'
            '• Si tenías estrictamente la menor puntuación: PUNTOS - 10.\n'
            '• Si NO tenías la menor o hay EMPATE: PUNTOS + 30.\n'
            '• Todos los demás suman los puntos de sus cartas.',
            Colors.cyanAccent,
          ),
          const SizedBox(height: 8),
          _caseBox(
            'CASO 2: ALGUIEN SE QUEDA SIN CARTAS',
            'Cuando llegue el turno del jugador que tiene 0 cartas, se canta automáticamente "Soy el que tiene menos cartas" y se aplican las reglas del Caso 1.',
            Colors.greenAccent,
          ),
          const SizedBox(height: 8),
          _caseBox(
            'CASO 3: SE AGOTA EL MAZO DE ROBO',
            'Se cuentan todos los puntos de la mesa. El jugador que tenga MENOS puntos recibe una penalización de +100 PUNTOS (para evitar estancar la partida). Los demás suman sus puntos normales.',
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _ruleHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 13,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _ruleText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Courier',
          height: 1.3,
        ),
      ),
    );
  }

  Widget _valueItem(String card, String desc, {bool highlight = false, Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? color.withAlpha(40) : Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: highlight ? color : Colors.white24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              card,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(color: highlight ? color : Colors.white70, fontFamily: 'Courier', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerItem(String rank, String name, String desc) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amberAccent.withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(4)),
            child: Text(
              rank,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontFamily: 'Courier', fontSize: 12),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _caseBox(String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Courier', fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}
