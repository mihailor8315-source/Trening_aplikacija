import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/workout.dart';
import 'add_workout_screen.dart';
import 'workout_detail_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Workout> _workouts = [];
  final Map<int, int> _exerciseCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final workouts = await DatabaseHelper.instance.getAllWorkouts();
    final counts = <int, int>{};
    for (final w in workouts) {
      counts[w.id!] = await DatabaseHelper.instance.getExerciseCount(w.id!);
    }
    if (!mounted) return;
    setState(() {
      _workouts = workouts;
      _exerciseCounts.clear();
      _exerciseCounts.addAll(counts);
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete(Workout workout) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši trening'),
        content: Text('Obrisati "${workout.name}"? Sve vježbe u ovom treningu će biti obrisane.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteWorkout(workout.id!);
      _load();
    }
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];
    const months = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}.';
  }

  String _exerciseLabel(int n) {
    if (n == 1) return '1 vežba';
    if (n >= 2 && n <= 4) return '$n vežbe';
    return '$n vežbi';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moj Trening'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Napredak',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgressScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
              ? _EmptyState(
                  icon: Icons.fitness_center,
                  title: 'Nema treninga',
                  subtitle: 'Dodaj prvi trening pritiskom na dugme ispod.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: _workouts.length,
                    itemBuilder: (_, i) {
                      final w = _workouts[i];
                      final count = _exerciseCounts[w.id] ?? 0;
                      return _WorkoutCard(
                        workout: w,
                        exerciseLabel: _exerciseLabel(count),
                        dateLabel: _formatDate(w.date),
                        colorScheme: cs,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkoutDetailScreen(workout: w),
                            ),
                          );
                          _load();
                        },
                        onDelete: () => _confirmDelete(w),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWorkoutScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novi trening'),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final String exerciseLabel;
  final String dateLabel;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutCard({
    required this.workout,
    required this.exerciseLabel,
    required this.dateLabel,
    required this.colorScheme,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.fitness_center, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(dateLabel, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 2),
                    Text(exerciseLabel, style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: onDelete,
                tooltip: 'Obriši',
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: cs.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
