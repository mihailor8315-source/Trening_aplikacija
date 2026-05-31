import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../widgets/exercise_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class for exercises not yet persisted
// ─────────────────────────────────────────────────────────────────────────────

class _PendingExercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;

  const _PendingExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  String get summary {
    final w = weight % 1 == 0 ? '${weight.toInt()}' : weight.toStringAsFixed(1);
    return '$sets × $reps @ $w kg';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Workout Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<_PendingExercise> _exercises = [];
  List<String> _previousExercises = [];

  @override
  void initState() {
    super.initState();
    _loadPrevious();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPrevious() async {
    final names = await DatabaseHelper.instance.getAllExerciseNames();
    if (mounted) setState(() => _previousExercises = names);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _addExercise() async {
    final ex = await showModalBottomSheet<_PendingExercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddExerciseSheet(previousExercises: _previousExercises),
      ),
    );
    if (ex != null) setState(() => _exercises.add(ex));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final workout = Workout(
      name: _nameController.text.trim(),
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final workoutId = await DatabaseHelper.instance.insertWorkout(workout);
    for (final ex in _exercises) {
      await DatabaseHelper.instance.insertExercise(Exercise(
        workoutId: workoutId,
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        weight: ex.weight,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime d) {
    const months = [
      'januar', 'februar', 'mart', 'april', 'maj', 'jun',
      'jul', 'avgust', 'septembar', 'oktobar', 'novembar', 'decembar'
    ];
    return '${d.day}. ${months[d.month - 1]} ${d.year}.';
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
        title: const Text('Novi trening'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Sačuvaj', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Naziv treninga ────────────────────────────────
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Naziv treninga *',
                hintText: 'npr. Trening A – Noge',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Naziv je obavezan' : null,
            ),
            const SizedBox(height: 16),

            // ── Datum ─────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text('Datum: ${_formatDate(_selectedDate)}'),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // ── Bilješke ──────────────────────────────────────
            TextFormField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Beleške (opciono)',
                hintText: 'Osećaj, fokus treninga...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            // ── Sekcija: Vježbe ───────────────────────────────
            Row(
              children: [
                const Icon(Icons.sports_gymnastics, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Vežbe',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_exercises.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _exerciseLabel(_exercises.length),
                      style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── Lista vježbi ──────────────────────────────────
            ..._exercises.asMap().entries.map((entry) {
              final i = entry.key;
              final ex = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    foregroundColor: cs.onSecondaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(ex.summary),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: cs.error),
                    tooltip: 'Ukloni',
                    onPressed: () => setState(() => _exercises.removeAt(i)),
                  ),
                ),
              );
            }),

            // ── Dugme: Dodaj vježbu ───────────────────────────
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj vežbu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet for adding a single exercise (not persisted yet)
// ─────────────────────────────────────────────────────────────────────────────

class _AddExerciseSheet extends StatefulWidget {
  final List<String> previousExercises;

  const _AddExerciseSheet({required this.previousExercises});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExercisePickerSheet(
        initialSearch: _nameController.text,
        previousExercises: widget.previousExercises,
      ),
    );
    if (selected != null) {
      setState(() => _nameController.text = selected);
      _formKey.currentState?.validate();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PendingExercise(
        name: _nameController.text.trim(),
        sets: int.parse(_setsController.text.trim()),
        reps: int.parse(_repsController.text.trim()),
        weight: double.parse(_weightController.text.trim().replaceAll(',', '.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Text(
                  'Dodaj vežbu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Naziv
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Naziv vežbe *',
                      hintText: 'Upiši ili odaberi iz baze',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.sports_gymnastics),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.list_alt_rounded),
                        tooltip: 'Baza vežbi',
                        onPressed: _openPicker,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Naziv je obavezan' : null,
                  ),
                  const SizedBox(height: 14),

                  // Serije + ponavljanja
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _setsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Serije *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            return (n == null || n <= 0) ? 'Upiši broj' : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ponavljanja *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            return (n == null || n <= 0) ? 'Upiši broj' : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Težina
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Težina (kg) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                      suffixText: 'kg',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v?.trim().replaceAll(',', '.') ?? '');
                      return (n == null || n < 0) ? 'Upiši težinu (0 za telesnu težinu)' : null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Potvrda
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj vežbu'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
