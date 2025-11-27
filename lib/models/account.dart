class Account {
  String id;
  String name;
  double initialBalance;
  String type;

  Account({
    this.id = '',
    required this.name,
    required this.initialBalance,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'initialBalance': initialBalance,
      'type': type,
    };
  }

  factory Account.fromMap(Map<String, dynamic> data, String id) {
    return Account(
      id: id,
      name: data['name'] ?? '',
      initialBalance: (data['initialBalance'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'Real',
    );
  }
}