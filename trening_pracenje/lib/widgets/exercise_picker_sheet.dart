import 'package:flutter/material.dart';
import '../data/exercise_list.dart';

class ExercisePickerSheet extends StatefulWidget {
  final String initialSearch;
  final List<String> previousExercises;

  const ExercisePickerSheet({
    super.key,
    required this.initialSearch,
    required this.previousExercises,
  });

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';
  String _selectedCategory = 'Sve';

  static const _allCategories = ['Sve', ...kExerciseCategories];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    _query = widget.initialSearch;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Widget> _buildItems(ColorScheme cs) {
    final q = _query.toLowerCase();
    final items = <Widget>[];

    if (_selectedCategory == 'Sve') {
      final prev = widget.previousExercises
          .where((e) => q.isEmpty || e.toLowerCase().contains(q))
          .toList();
      if (prev.isNotEmpty) {
        items.add(_SectionHeader(label: 'Prethodno korišćeno', cs: cs));
        for (final name in prev) {
          items.add(_ExerciseTile(name: name, onTap: () => Navigator.pop(context, name)));
        }
        items.add(const Divider(height: 24));
      }
    }

    final exercises = kExerciseTemplates.where((e) {
      final matchCat = _selectedCategory == 'Sve' || e.category == _selectedCategory;
      final matchQ = q.isEmpty || e.name.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();

    if (exercises.isNotEmpty) {
      final label = _selectedCategory == 'Sve'
          ? 'Baza vežbi (${exercises.length})'
          : '$_selectedCategory (${exercises.length})';
      items.add(_SectionHeader(label: label, cs: cs));
      String? lastCat;
      for (final ex in exercises) {
        if (_selectedCategory == 'Sve' && ex.category != lastCat) {
          lastCat = ex.category;
          items.add(_CategorySubHeader(label: ex.category, cs: cs));
        }
        items.add(_ExerciseTile(name: ex.name, onTap: () => Navigator.pop(context, ex.name)));
      }
    }

    if (items.isEmpty) {
      items.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Nema rezultata za "$_query"',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _buildItems(cs);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
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
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
            child: Row(
              children: [
                Text(
                  'Baza vežbi',
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: widget.initialSearch.isEmpty,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Pretraži vežbe...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _allCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _allCategories[i];
                return FilterChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionHeader({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 0.4),
      ),
    );
  }
}

class _CategorySubHeader extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _CategorySubHeader({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _ExerciseTile({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(name),
      trailing: const Icon(Icons.add_circle_outline, size: 20),
      onTap: onTap,
    );
  }
}
