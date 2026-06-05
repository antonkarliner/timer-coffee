// tool/generate_seed.dart
//
// Re-runnable generator for the bundled offline-fallback seed assets.
//
// It pulls the public recipe catalog (+ localizations + steps), brewing methods,
// supported locales, and coffee facts from Supabase via PostgREST — using the SAME
// select shapes as the runtime sync in `lib/providers/database_provider.dart` — and
// writes them to `assets/data/seed/*.json`. Those JSON files mirror the Supabase
// nested-select response shape exactly, so the app reuses the existing
// `*CompanionExtension.fromJson` parsers in `lib/database/extensions.dart` verbatim.
//
// Run before each release to refresh the snapshot, then commit `assets/data/seed/`:
//
//   dart run tool/generate_seed.dart
//
// Credentials are read from `.env.local` (SUPA_URL / SUPA_KEY) — the same file the
// app's `envied` config reads. Nothing is hardcoded.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _seedDir = 'assets/data/seed';

Future<void> main() async {
  final env = _loadEnv('.env.local');
  final url = env['SUPA_URL'];
  final key = env['SUPA_KEY'];
  if (url == null || key == null || url.isEmpty || key.isEmpty) {
    stderr.writeln('Missing SUPA_URL / SUPA_KEY in .env.local');
    exit(1);
  }

  final rest = '${url.replaceAll(RegExp(r'/$'), '')}/rest/v1';
  final headers = {
    'apikey': key,
    'Authorization': 'Bearer $key',
    'Accept': 'application/json',
  };

  await Directory(_seedDir).create(recursive: true);

  // 1. Recipes (+ nested localizations + steps). Mirrors:
  //    .from('recipes').select('*, recipe_localization(*), steps(*)')
  // Exclude user-created recipes (id starts with 'usr-') — only the public catalog
  // belongs in an offline first-launch snapshot. RLS already restricts the anon key
  // to publishable rows; the filter below is belt-and-suspenders.
  final recipes = await _fetchAll(
    rest,
    headers,
    'recipes',
    'select=*,recipe_localization(*),steps(*)&id=not.like.usr-*',
  );
  await _write('recipes.json', recipes);

  // 2. Brewing methods. Mirrors: .select('brewing_method_id,brewing_method')
  final brewingMethods = await _fetchAll(
    rest,
    headers,
    'brewing_methods',
    'select=brewing_method_id,brewing_method',
  );
  await _write('brewing_methods.json', brewingMethods);

  // 3. Supported locales. Mirrors: .from('supported_locales').select()
  final supportedLocales = await _fetchAll(
    rest,
    headers,
    'supported_locales',
    'select=*',
  );
  await _write('supported_locales.json', supportedLocales);

  // 4. Coffee facts. Mirrors: .from('coffee_facts').select()
  final coffeeFacts = await _fetchAll(
    rest,
    headers,
    'coffee_facts',
    'select=*',
  );
  await _write('coffee_facts.json', coffeeFacts);

  stdout.writeln('\nSeed generation complete:');
  stdout.writeln('  recipes.json            ${recipes.length} rows');
  stdout.writeln('  brewing_methods.json    ${brewingMethods.length} rows');
  stdout.writeln('  supported_locales.json  ${supportedLocales.length} rows');
  stdout.writeln('  coffee_facts.json       ${coffeeFacts.length} rows');
}

/// Fetches every row from a PostgREST table/view, paging past the server row cap.
Future<List<dynamic>> _fetchAll(
  String rest,
  Map<String, String> headers,
  String table,
  String query,
) async {
  const pageSize = 1000;
  final all = <dynamic>[];
  var offset = 0;
  while (true) {
    final uri = Uri.parse('$rest/$table?$query');
    final res = await http.get(
      uri,
      headers: {
        ...headers,
        'Range-Unit': 'items',
        'Range': '$offset-${offset + pageSize - 1}',
      },
    );
    if (res.statusCode != 200 && res.statusCode != 206) {
      stderr.writeln('GET $table failed: ${res.statusCode} ${res.body}');
      exit(1);
    }
    final page = jsonDecode(res.body) as List<dynamic>;
    all.addAll(page);
    if (page.length < pageSize) break;
    offset += pageSize;
  }
  return all;
}

Future<void> _write(String fileName, List<dynamic> rows) async {
  final file = File('$_seedDir/$fileName');
  await file.writeAsString(jsonEncode(rows));
  stdout.writeln('wrote $_seedDir/$fileName');
}

Map<String, String> _loadEnv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('$path not found');
    exit(1);
  }
  final out = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final k = line.substring(0, eq).trim();
    var v = line.substring(eq + 1).trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")))) {
      v = v.substring(1, v.length - 1);
    }
    out[k] = v;
  }
  return out;
}
