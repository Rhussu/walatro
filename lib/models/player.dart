class Player {
  final String name;
  final bool isHost;
  bool isReady;

  Player({required this.name, required this.isHost, required this.isReady});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      isHost: json['isHost'] ?? false,
      isReady: json['isReady'] ?? false,
    );
  }
}
