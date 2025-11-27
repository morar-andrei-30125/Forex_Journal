class Strategy {
  String id;
  String name;
  String description;

  Strategy({
    this.id = '',
    required this.name,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  factory Strategy.fromMap(Map<String, dynamic> data, String id) {
    return Strategy(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
    );
  }
}