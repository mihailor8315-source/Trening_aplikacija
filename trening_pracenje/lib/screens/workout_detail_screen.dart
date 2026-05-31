import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import 'add_exercise_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getExercisesForWorkout(widget.workout.id!);
    if (!mounted) return;
    setState(() {
      _exercises = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    await DatabaseHelper.instance.deleteExercise(exercise.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${exercise.name}" obrisana'),
        action: SnackBarAction(
          label: 'U redu',
          onPressed: () {},
        ),
      ),
    );
    _load();
  }

  Future<bool?> _confirmDismiss(Exercise exercise) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši vežbu'),
        content: Text('Obrisati "${exercise.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Ponedeljak', 'Utorak', 'Sreda', 'Četvrtak', 'Petak', 'Subota', 'Nedelja'];
    const months = [
      'januar', 'februar', 'mart', 'april', 'maj', 'jun',
      'jul', 'avgust', 'septembar', 'oktobar', 'novembar', 'decembar'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}.';
  }

  String _weightStr(double w) =>
      w % 1 == 0 ? '${w.toInt()} kg' : '${w.toStringAsFixed(1)} kg';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final workout = widget.workout;

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info header ──────────────────────────────────
          Container(
            width: double.infinity,
            color: cs.primaryContainer.withValues(alpha: 0.25),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 15, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(_formatDate(workout.date), style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined, size: 15, color: cs.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          workout.notes!,
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Sekcija vježbi ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(
                  'Vežbe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (!_isLoading)
                  Chip(
                    label: Text('${_exercises.length}'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_gymnastics, size: 64, color: cs.primary.withValues(alpha: 0.35)),
                            const SizedBox(height: 14),
                            const Text('Nema vežbi'),
                            const SizedBox(height: 6),
                            Text(
                              'Pritisni + da dodaš prvu vežbu.',
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: _exercises.length,
                        itemBuilder: (_, i) {
                          final ex = _exercises[i];
                          return Dismissible(
                            key: Key('ex_${ex.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDismiss(ex),
                            onDismissed: (_) => _deleteExercise(ex),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.delete_outline, color: cs.onError),
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.secondaryContainer,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${ex.sets} × ${ex.reps} ponavljanja • ${_weightStr(ex.weight)}'),
                                trailing: Icon(Icons.drag_handle, color: cs.onSurface.withValues(alpha: 0.3)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExerciseScreen(workoutId: workout.id!),
            ),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
