class RecipeCollectionModel {
  final String id;
  final String emoji;
  final int displayOrder;
  final String name;
  final String? description;

  const RecipeCollectionModel({
    required this.id,
    required this.emoji,
    required this.displayOrder,
    required this.name,
    this.description,
  });
}
