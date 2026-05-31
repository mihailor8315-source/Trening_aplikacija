class Exercise {
  final int? id;
  final int workoutId;     // kojim treningu pripada
  final String name;       // npr. "Bench press"
  final int sets;          // broj serija
  final int reps;          // broj ponavljanja
  final double weight;     // težina u kg

  Exercise({
    this.id,
    required this.workoutId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      workoutId: map['workoutId'],
      name: map['name'],
      sets: map['sets'],
      reps: map['reps'],
      weight: map['weight'],
    );
  }
}