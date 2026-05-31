import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../widgets/exercise_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class for exercises in edit mode (existing + new)
// ─────────────────────────────────────────────────────────────────────────────

class _EditableExercise {
  final int? id;
  final String name;
  final int sets;
  final int reps;
  final double weight;

  const _EditableExercise({
    this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  String get summary {
    final w = weight % 1 == 0 ? '${weight.toInt()}' : weight.toStringAsFixed(1);
    return '$sets × $reps @ $w kg';
  }

  _EditableExercise copyWith({String? name, int? sets, int? reps, double? weight}) {
    return _EditableExercise(
      id: id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Workout Screen
// ─────────────────────────────────────────────────────────────────────────────

class EditWorkoutScreen extends StatefulWidget {
  final Workout workout;

  const EditWorkoutScreen({super.key, required this.workout});

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isSaving = false;
  bool _isLoading = true;

  final List<_EditableExercise> _exercises = [];
  List<String> _previousExercises = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _notesController = TextEditingController(text: widget.workout.notes ?? '');
    _selectedDate = widget.workout.date;
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final exercises = await DatabaseHelper.instance.getExercisesForWorkout(widget.workout.id!);
    final names = await DatabaseHelper.instance.getAllExerciseNames();
    if (!mounted) return;
    setState(() {
      _exercises.addAll(exercises.map((e) => _EditableExercise(
            id: e.id,
            name: e.name,
            sets: e.sets,
            reps: e.reps,
            weight: e.weight,
          )));
      _previousExercises = names;
      _isLoading = false;
    });
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
    final ex = await showModalBottomSheet<_EditableExercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ExerciseFormSheet(previousExercises: _previousExercises),
      ),
    );
    if (ex != null) setState(() => _exercises.add(ex));
  }

  Future<void> _editExercise(int index) async {
    final current = _exercises[index];
    final updated = await showModalBottomSheet<_EditableExercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ExerciseFormSheet(
          previousExercises: _previousExercises,
          initial: current,
        ),
      ),
    );
    if (updated != null) {
      setState(() => _exercises[index] = current.copyWith(
            name: updated.name,
            sets: updated.sets,
            reps: updated.reps,
            weight: updated.weight,
          ));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = Workout(
      id: widget.workout.id,
      name: _nameController.text.trim(),
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await DatabaseHelper.instance.updateWorkout(updated);
    await DatabaseHelper.instance.deleteExercisesForWorkout(widget.workout.id!);
    for (final ex in _exercises) {
      await DatabaseHelper.instance.insertExercise(Exercise(
        workoutId: widget.workout.id!,
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        weight: ex.weight,
      ));
    }

    if (mounted) Navigator.pop(context, true);
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
        title: const Text('Izmeni trening'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Naziv treninga ────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Naziv treninga *',
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

                  // ── Beleške ───────────────────────────────────────
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

                  // ── Sekcija: Vežbe ────────────────────────────────
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
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Lista vežbi ───────────────────────────────────
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: cs.primary),
                              tooltip: 'Izmeni',
                              onPressed: () => _editExercise(i),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: cs.error),
                              tooltip: 'Ukloni',
                              onPressed: () => setState(() => _exercises.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // ── Dugme: Dodaj vežbu ────────────────────────────
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
// Bottom sheet for adding or editing a single exercise
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseFormSheet extends StatefulWidget {
  final List<String> previousExercises;
  final _EditableExercise? initial;

  const _ExerciseFormSheet({required this.previousExercises, this.initial});

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameController = TextEditingController(text: init?.name ?? '');
    _setsController = TextEditingController(text: init?.sets.toString() ?? '3');
    _repsController = TextEditingController(text: init?.reps.toString() ?? '10');
    final w = init?.weight ?? 0.0;
    _weightController = TextEditingController(
      text: w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1),
    );
  }

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
      _EditableExercise(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Izmeni vežbu' : 'Dodaj vežbu',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Naziv vežbe *',
                      hintText: 'Upiši ili izaberi iz baze',
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
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: Icon(_isEditing ? Icons.check : Icons.add),
                    label: Text(_isEditing ? 'Sačuvaj izmene' : 'Dodaj vežbu'),
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
