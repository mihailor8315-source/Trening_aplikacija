class Workout {
  final int? id;
  final String name;
  final DateTime date;
  final String? notes;

  Workout({
    this.id,
    required this.name,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'date': date.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
