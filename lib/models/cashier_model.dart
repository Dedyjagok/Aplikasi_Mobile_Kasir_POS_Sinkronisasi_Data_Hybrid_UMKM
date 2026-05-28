class Cashier {
  final String id;
  final String userId; // UID owner
  final String name;
  final String pin;
  final bool isActive;

  Cashier({
    required this.id,
    required this.userId,
    required this.name,
    required this.pin,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'pin': pin,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Cashier.fromMap(Map<String, dynamic> map) {
    return Cashier(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      pin: map['pin'],
      isActive: map['is_active'] == 1,
    );
  }
}
