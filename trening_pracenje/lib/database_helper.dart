import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/workout.dart';
import 'models/exercise.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trening.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutId INTEGER NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (workoutId) REFERENCES workouts(id) ON DELETE CASCADE
      )
    ''');
  }

  // ─── WORKOUT ────────────────────────────────────────────

  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<List<Workout>> getAllWorkouts() async {
    final db = await database;
    final result = await db.query('workouts', orderBy: 'date DESC');
    return result.map(Workout.fromMap).toList();
  }

  Future<Workout?> getWorkout(int id) async {
    final db = await database;
    final result = await db.query('workouts', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Workout.fromMap(result.first);
  }

  Future<int> deleteWorkout(int id) async {
    final db = await database;
    return await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── EXERCISE ────────────────────────────────────────────

  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getExercisesForWorkout(int workoutId) async {
    final db = await database;
    final result = await db.query(
      'exercises',
      where: 'workoutId = ?',
      whereArgs: [workoutId],
    );
    return result.map(Exercise.fromMap).toList();
  }

  Future<int> getExerciseCount(int workoutId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM exercises WHERE workoutId = ?',
      [workoutId],
    );
    return result.first['count'] as int;
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ─── NAPREDAK ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProgressForExercise(String name) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT e.*, w.date, w.name as workoutName
      FROM exercises e
      JOIN workouts w ON e.workoutId = w.id
      WHERE LOWER(e.name) = LOWER(?)
      ORDER BY w.date ASC
    ''', [name]);
  }

  Future<List<String>> getAllExerciseNames() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT LOWER(name) as name FROM exercises ORDER BY name',
    );
    return result.map((row) => row['name'] as String).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
