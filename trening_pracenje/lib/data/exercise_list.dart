class ExerciseTemplate {
  final String name;
  final String category;

  const ExerciseTemplate({required this.name, required this.category});
}

const List<String> kExerciseCategories = [
  'Grudi',
  'Leđa',
  'Noge',
  'Ramena',
  'Bicepsi',
  'Tricepsi',
  'Core',
];

const List<ExerciseTemplate> kExerciseTemplates = [
  // ── Grudi ────────────────────────────────────────────────
  ExerciseTemplate(name: 'Bench press',                    category: 'Grudi'),
  ExerciseTemplate(name: 'Kosi bench press',               category: 'Grudi'),
  ExerciseTemplate(name: 'Spušteni bench press',           category: 'Grudi'),
  ExerciseTemplate(name: 'Bučice na ravnoj klupi',         category: 'Grudi'),
  ExerciseTemplate(name: 'Kosi potisak bučicama',          category: 'Grudi'),
  ExerciseTemplate(name: 'Cable crossover',                category: 'Grudi'),
  ExerciseTemplate(name: 'Pec deck',                       category: 'Grudi'),
  ExerciseTemplate(name: 'Dipovi (grudi)',                  category: 'Grudi'),

  // ── Leđa ─────────────────────────────────────────────────
  ExerciseTemplate(name: 'Mrtvo dizanje',                  category: 'Leđa'),
  ExerciseTemplate(name: 'Zgibovi',                        category: 'Leđa'),
  ExerciseTemplate(name: 'Lat pulldown',                   category: 'Leđa'),
  ExerciseTemplate(name: 'Veslanje šipkom',                category: 'Leđa'),
  ExerciseTemplate(name: 'Veslanje bučicom',               category: 'Leđa'),
  ExerciseTemplate(name: 'Sedeće veslanje na kablovima',   category: 'Leđa'),
  ExerciseTemplate(name: 'T-bar veslanje',                 category: 'Leđa'),
  ExerciseTemplate(name: 'Face pull',                      category: 'Leđa'),
  ExerciseTemplate(name: 'Hiperekstenzija',                category: 'Leđa'),

  // ── Noge ─────────────────────────────────────────────────
  ExerciseTemplate(name: 'Čučanj',                         category: 'Noge'),
  ExerciseTemplate(name: 'Leg press',                      category: 'Noge'),
  ExerciseTemplate(name: 'Iskoraci',                       category: 'Noge'),
  ExerciseTemplate(name: 'Leg extension',                  category: 'Noge'),
  ExerciseTemplate(name: 'Leg curl (ležeći)',               category: 'Noge'),
  ExerciseTemplate(name: 'Rumunsko mrtvo dizanje',         category: 'Noge'),
  ExerciseTemplate(name: 'Bugarski split čučanj',          category: 'Noge'),
  ExerciseTemplate(name: 'Podizanje na prste stojeći',     category: 'Noge'),
  ExerciseTemplate(name: 'Hack čučanj',                    category: 'Noge'),
  ExerciseTemplate(name: 'Goblet čučanj',                  category: 'Noge'),

  // ── Ramena ───────────────────────────────────────────────
  ExerciseTemplate(name: 'Vojnički potisak',               category: 'Ramena'),
  ExerciseTemplate(name: 'Potisak bučicama sedeći',        category: 'Ramena'),
  ExerciseTemplate(name: 'Bočno podizanje',                category: 'Ramena'),
  ExerciseTemplate(name: 'Prednje podizanje',              category: 'Ramena'),
  ExerciseTemplate(name: 'Stražnji deltoid na kablu',      category: 'Ramena'),
  ExerciseTemplate(name: 'Arnold press',                   category: 'Ramena'),
  ExerciseTemplate(name: 'Uspravljeno veslanje',           category: 'Ramena'),
  ExerciseTemplate(name: 'Trapezi (šrug)',                  category: 'Ramena'),

  // ── Bicepsi ──────────────────────────────────────────────
  ExerciseTemplate(name: 'Uvijanje šipkom (biceps)',       category: 'Bicepsi'),
  ExerciseTemplate(name: 'Uvijanje bučicama',              category: 'Bicepsi'),
  ExerciseTemplate(name: 'Hammer curl',                    category: 'Bicepsi'),
  ExerciseTemplate(name: 'Preacher curl',                  category: 'Bicepsi'),
  ExerciseTemplate(name: 'Uvijanje na kablu',              category: 'Bicepsi'),

  // ── Tricepsi ─────────────────────────────────────────────
  ExerciseTemplate(name: 'Skull crusher',                  category: 'Tricepsi'),
  ExerciseTemplate(name: 'Potisak na kablu (triceps)',     category: 'Tricepsi'),
  ExerciseTemplate(name: 'Nadglavni potisak bučicom',      category: 'Tricepsi'),
  ExerciseTemplate(name: 'Dipovi (triceps)',                category: 'Tricepsi'),
  ExerciseTemplate(name: 'Kickback (triceps)',              category: 'Tricepsi'),

  // ── Core ─────────────────────────────────────────────────
  ExerciseTemplate(name: 'Plank',                          category: 'Core'),
  ExerciseTemplate(name: 'Krančevi',                       category: 'Core'),
  ExerciseTemplate(name: 'Ruske rotacije',                 category: 'Core'),
  ExerciseTemplate(name: 'Podizanje nogu',                 category: 'Core'),
  ExerciseTemplate(name: 'Ab wheel rollout',               category: 'Core'),
];
