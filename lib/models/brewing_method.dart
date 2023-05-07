class BrewingMethod {
  final String id;
  final String name;

  BrewingMethod({required this.id, required this.name});

  factory BrewingMethod.fromJson(Map<String, dynamic> json) {
    return BrewingMethod(
      id: json['id'],
      name: json['name'],
    );
  }
}
