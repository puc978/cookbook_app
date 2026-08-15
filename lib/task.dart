class Task {
  final int? id;
  final String recipeName;
  final String? ingredients;
  final String? instruction;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    this.id,
    required this.recipeName,
    this.ingredients,
    this.instruction,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeName': recipeName,
      'ingredients': ingredients,
      'instruction': instruction,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      recipeName: map['recipeName'],
      ingredients: map['ingredients'],
      instruction: map['instruction'],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, recipeName: $recipeName, isCompleted: $isCompleted)';
  }
}