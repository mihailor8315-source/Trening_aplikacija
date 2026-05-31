class Workout {
  final int? id;
  final String name;       // npr. "Trening A – ponedeljak"
  final DateTime date;
  final String? notes;

  Workout({
    this.id,
    required this.name,
    required this.date,
    this.notes,
  });

  // Pretvara objekat u Map za SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  // Pravi objekat iz Map-a koji dolazi iz SQLite
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      name: map['name'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }
}