import 'package:flutter/material.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // Contenido
          SafeArea(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Create room", style: TextStyle(color: Colors.white)),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          padding: const EdgeInsets.all(50),
                          backgroundColor:
                              Colors.transparent, // Fondo azul con opacidad
                        ),
                        child: const Icon(
                          Icons.add_home,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 50), // Espacio entre los botones

                  Column(
                    
                    mainAxisAlignment: MainAxisAlignment.center,  
                    children: [
                      Text("Join room", style: TextStyle(color: Colors.white)),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          padding: const EdgeInsets.all(50),
                          backgroundColor:
                              Colors.transparent, // Fondo azul con opacidad
                        ),
                        child: const Icon(
                          Icons.meeting_room,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
