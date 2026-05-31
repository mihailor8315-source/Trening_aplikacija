import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<String> _exerciseNames = [];
  String? _selected;
  List<Map<String, dynamic>> _rows = [];
  bool _loadingNames = true;
  bool _loadingProgress = false;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final names = await DatabaseHelper.instance.getAllExerciseNames();
    if (!mounted) return;
    setState(() {
      _exerciseNames = names;
      _loadingNames = false;
    });
  }

  Future<void> _loadProgress(String name) async {
    setState(() {
      _selected = name;
      _loadingProgress = true;
    });
    final data = await DatabaseHelper.instance.getProgressForExercise(name);
    if (!mounted) return;
    setState(() {
      _rows = data;
      _loadingProgress = false;
    });
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    const months = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];
    return '${d.day}. ${months[d.month - 1]} ${d.year}.';
  }

  String _weightStr(num w) {
    final d = w.toDouble();
    return d % 1 == 0 ? '${d.toInt()} kg' : '${d.toStringAsFixed(1)} kg';
  }

  // Epley formula
  double _calcE1RM(int reps, double weight) {
    if (reps <= 0 || weight <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Napredak')),
      body: _loadingNames
          ? const Center(child: CircularProgressIndicator())
          : _exerciseNames.isEmpty
              ? _EmptyState(cs: cs)
              : Column(
                  children: [
                    // ── Odabir vježbe ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Izaberi vežbu',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sports_gymnastics),
                          contentPadding: EdgeInsets.fromLTRB(12, 4, 12, 4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selected,
                            isExpanded: true,
                            hint: const Text('Izaberi...'),
                            items: _exerciseNames
                                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _loadProgress(v);
                            },
                          ),
                        ),
                      ),
                    ),

                    // ── Sadržaj ──────────────────────────────────
                    Expanded(
                      child: _selected == null
                          ? Center(
                              child: Text(
                                'Izaberi vežbu da vidiš napredak.',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
                              ),
                            )
                          : _loadingProgress
                              ? const Center(child: CircularProgressIndicator())
                              : _rows.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nema podataka za "$_selected".',
                                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
                                      ),
                                    )
                                  : _buildContent(cs),
                    ),
                  ],
                ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    double maxWeight = 0;
    double maxVolume = 0;
    double maxE1RM = 0;

    for (final r in _rows) {
      final w = (r['weight'] as num).toDouble();
      final reps = r['reps'] as int;
      final sets = r['sets'] as int;
      final vol = sets * reps * w;
      final e1rm = _calcE1RM(reps, w);
      if (w > maxWeight) maxWeight = w;
      if (vol > maxVolume) maxVolume = vol;
      if (e1rm > maxE1RM) maxE1RM = e1rm;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Stats: sesija + maks. težina ─────────────
        Row(
          children: [
            _StatChip(label: 'Sesija', value: '${_rows.length}', icon: Icons.calendar_month, cs: cs),
            const SizedBox(width: 10),
            _StatChip(label: 'Maks. težina', value: _weightStr(maxWeight), icon: Icons.emoji_events_outlined, cs: cs),
          ],
        ),
        const SizedBox(height: 10),

        // ── Stats: procijenjeni 1RM ───────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, size: 22, color: cs.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Procenjeni maks. 1RM (e1RM)',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.65)),
                  ),
                  Text(
                    '≈ ${_weightStr(maxE1RM)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Epley formula',
                style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.38)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Grafik e1RM ───────────────────────────────
        _buildChart(cs),
        const SizedBox(height: 16),

        // ── Naslov liste ──────────────────────────────
        Text('Istorija (${_rows.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // ── Lista unosa ───────────────────────────────
        ..._rows.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final w = (r['weight'] as num).toDouble();
          final reps = r['reps'] as int;
          final sets = r['sets'] as int;
          final vol = sets * reps * w;
          final e1rm = _calcE1RM(reps, w);
          final isPR = w == maxWeight;
          final isBestE1RM = maxE1RM > 0 && e1rm == maxE1RM;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isBestE1RM ? cs.primaryContainer.withValues(alpha: 0.5) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isBestE1RM ? cs.primary : cs.surfaceContainerHighest,
                foregroundColor: isBestE1RM ? cs.onPrimary : cs.onSurface,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              title: Row(
                children: [
                  Text('$sets × $reps @ ${_weightStr(w)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (isPR) ...[
                    const SizedBox(width: 5),
                    Icon(Icons.emoji_events, size: 15, color: cs.primary),
                  ],
                  if (isBestE1RM) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.bolt_rounded, size: 15, color: cs.primary),
                  ],
                ],
              ),
              subtitle: Text('${r['workoutName']}  •  ${_formatDate(r['date'] as String)}'),
              trailing: _E1RMBadge(e1rm: e1rm, maxE1rm: maxE1RM, volume: vol, maxVolume: maxVolume, cs: cs),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // e1RM chart with 3-session moving average
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildChart(ColorScheme cs) {
    final e1rmData = _rows.map((r) {
      final w = (r['weight'] as num).toDouble();
      final reps = r['reps'] as int;
      return _calcE1RM(reps, w);
    }).toList();

    if (e1rmData.every((v) => v == 0)) return const SizedBox.shrink();

    // 3-session moving average
    final maData = List.generate(e1rmData.length, (i) {
      final start = (i - 2).clamp(0, i);
      final slice = e1rmData.sublist(start, i + 1);
      return slice.reduce((a, b) => a + b) / slice.length;
    });

    final e1rmSpots = [for (int i = 0; i < e1rmData.length; i++) FlSpot(i.toDouble(), e1rmData[i])];
    final maSpots = [for (int i = 0; i < maData.length; i++) FlSpot(i.toDouble(), maData[i])];

    final allVals = [...e1rmData, ...maData];
    final maxVal = allVals.reduce(math.max);
    final minVal = allVals.reduce(math.min);
    final spread = math.max(maxVal - minVal, 5.0);
    final maxY = maxVal + spread * 0.25;
    final minY = math.max(0.0, minVal - spread * 0.15);
    final maxX = math.max(e1rmData.length - 1.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  const Text('e1RM kroz sesije', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: cs.onSurface.withValues(alpha: 0.07),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (v, meta) {
                          if (v == meta.max || v == meta.min) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${v.toInt()} kg',
                              style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.45)),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Sesija',
                        style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.45)),
                      ),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if ((v - i).abs() > 0.01) return const SizedBox.shrink();
                          if (i < 0 || i >= _rows.length) return const SizedBox.shrink();
                          final n = _rows.length;
                          final step = n <= 6 ? 1 : (n <= 12 ? 2 : (n / 5).ceil());
                          if (i % step != 0 && i != n - 1) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.45)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItems: (spots) => spots.map((s) {
                        final i = s.x.round();
                        final isMA = s.barIndex == 1;
                        final date = (i >= 0 && i < _rows.length)
                            ? _formatDate(_rows[i]['date'] as String)
                            : '';
                        return LineTooltipItem(
                          isMA
                              ? 'Prosek: ≈${s.y.toStringAsFixed(1)} kg'
                              : '$date\ne1RM: ≈${s.y.toStringAsFixed(1)} kg',
                          TextStyle(
                            color: cs.onInverseSurface,
                            fontSize: 11,
                            fontWeight: isMA ? FontWeight.normal : FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    // Actual e1RM line
                    LineChartBarData(
                      spots: e1rmSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: cs.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 4,
                          color: cs.primary,
                          strokeColor: cs.surface,
                          strokeWidth: 1.5,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: cs.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    // 3-session moving average
                    LineChartBarData(
                      spots: maSpots,
                      isCurved: true,
                      curveSmoothness: 0.4,
                      color: cs.secondary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [6, 4],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: cs.primary, label: 'e1RM po sesiji'),
                const SizedBox(width: 24),
                _LegendItem(color: cs.secondary, label: 'Prosek (3 sesije)', dashed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat chip widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;

  const _StatChip({required this.label, required this.value, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.secondary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// e1RM badge per history entry
// ─────────────────────────────────────────────────────────────────────────────

class _E1RMBadge extends StatelessWidget {
  final double e1rm;
  final double maxE1rm;
  final double volume;
  final double maxVolume;
  final ColorScheme cs;

  const _E1RMBadge({
    required this.e1rm,
    required this.maxE1rm,
    required this.volume,
    required this.maxVolume,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (e1rm <= 0) return const SizedBox.shrink();
    final e1rmRatio = maxE1rm > 0 ? e1rm / maxE1rm : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('e1RM', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
        Text('≈ ${e1rm.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        SizedBox(
          width: 52,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: e1rmRatio,
              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
              color: cs.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart legend item
// ─────────────────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    Widget line;
    if (dashed) {
      line = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 2),
          Container(width: 5, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 2),
          Container(width: 5, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
        ],
      );
    } else {
      line = Container(
        width: 20,
        height: 2.5,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line,
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;

  const _EmptyState({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 80, color: cs.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            const Text('Nema podataka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Dodaj treninge sa vežbama da vidiš napredak ovde.',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
