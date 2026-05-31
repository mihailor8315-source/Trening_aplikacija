import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/exercise.dart';
import '../widgets/exercise_picker_sheet.dart';

class AddExerciseScreen extends StatefulWidget {
  final int workoutId;

  const AddExerciseScreen({super.key, required this.workoutId});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '0');
  List<String> _previousExercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrevious();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadPrevious() async {
    final names = await DatabaseHelper.instance.getAllExerciseNames();
    if (mounted) setState(() => _previousExercises = names);
  }

  Future<void> _openPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExercisePickerSheet(
        initialSearch: _nameController.text,
        previousExercises: _previousExercises,
      ),
    );
    if (selected != null) {
      _nameController.text = selected;
      _formKey.currentState?.validate();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final exercise = Exercise(
      workoutId: widget.workoutId,
      name: _nameController.text.trim(),
      sets: int.parse(_setsController.text.trim()),
      reps: int.parse(_repsController.text.trim()),
      weight: double.parse(_weightController.text.trim().replaceAll(',', '.')),
    );

    await DatabaseHelper.instance.insertExercise(exercise);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj vežbu'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Dodaj', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
            const SizedBox(height: 16),
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
                const SizedBox(width: 14),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            _PreviewCard(
              setsController: _setsController,
              repsController: _repsController,
              weightController: _weightController,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview Card
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewCard extends StatefulWidget {
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;

  const _PreviewCard({
    required this.setsController,
    required this.repsController,
    required this.weightController,
  });

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  @override
  void initState() {
    super.initState();
    widget.setsController.addListener(_rebuild);
    widget.repsController.addListener(_rebuild);
    widget.weightController.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.setsController.removeListener(_rebuild);
    widget.repsController.removeListener(_rebuild);
    widget.weightController.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sets = int.tryParse(widget.setsController.text) ?? 0;
    final reps = int.tryParse(widget.repsController.text) ?? 0;
    final weight = double.tryParse(widget.weightController.text.replaceAll(',', '.')) ?? 0;
    final volume = sets * reps * weight;

    return Card(
      color: cs.secondaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pregled', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary)),
            const SizedBox(height: 8),
            Text(
              '$sets × $reps @ ${weight % 1 == 0 ? weight.toInt() : weight} kg',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (volume > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Ukupni volumen: ${volume.toStringAsFixed(0)} kg',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
