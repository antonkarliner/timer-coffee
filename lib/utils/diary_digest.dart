import 'package:coffee_timer/models/diary_entry.dart';

class DiaryWeekDigest {
  const DiaryWeekDigest({
    required this.weekStart,
    required this.brewCount,
    required this.topMethodName,
    required this.bestCup,
    required this.dialIn,
  });

  final DateTime weekStart;
  final int brewCount;
  final String? topMethodName;
  final ({String label, double rating})? bestCup;
  final DiaryDialInFact? dialIn;
}

class DiaryDialInFact {
  const DiaryDialInFact({required this.beanName, required this.methodName});

  final String beanName;
  final String methodName;
}

DateTime diaryWeekStart(DateTime date) {
  final local = date.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Builds a weekly recap from the diary's already-loaded full history.
///
/// This deliberately follows the same in-memory approach as diary grouping and
/// the month strip. If the timeline is ever paginated, callers must move this
/// aggregation to the DAO so a week is never summarized from a partial window.
DiaryWeekDigest? buildWeekDigest(List<DiaryEntry> weekEntries) {
  if (weekEntries.length < 2) return null;

  final newestFirst = [...weekEntries]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final methodCounts = <String, int>{};
  for (final entry in newestFirst) {
    final method = entry.methodName.trim();
    if (method.isNotEmpty) {
      methodCounts.update(method, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  String? topMethodName;
  var topMethodCount = 0;
  for (final entry in newestFirst) {
    final method = entry.methodName.trim();
    final count = methodCounts[method] ?? 0;
    if (count > topMethodCount) {
      topMethodName = method;
      topMethodCount = count;
    }
  }

  DiaryEntry? bestEntry;
  for (final entry in newestFirst) {
    if (entry.rating == null) continue;
    if (bestEntry == null || entry.rating! > bestEntry.rating!) {
      bestEntry = entry;
    }
  }

  return DiaryWeekDigest(
    weekStart: diaryWeekStart(newestFirst.last.createdAt),
    brewCount: weekEntries.length,
    topMethodName: topMethodName,
    bestCup: bestEntry == null
        ? null
        : (
            label: bestEntry.beanName ?? bestEntry.recipeName,
            rating: bestEntry.rating!,
          ),
    dialIn: _findDialInFact(newestFirst),
  );
}

DiaryDialInFact? _findDialInFact(List<DiaryEntry> newestFirst) {
  final series = <(String, String), List<DiaryEntry>>{};
  for (final entry in newestFirst.reversed) {
    final beanUuid = entry.normalizedBagIdentity;
    final methodId = entry.brewingMethodId.trim();
    if (beanUuid == null || methodId.isEmpty) continue;
    series.putIfAbsent((beanUuid, methodId), () => []).add(entry);
  }

  final candidates = <DiaryEntry>[];
  for (final group in series.entries) {
    final attempts = group.value;
    if (attempts.length < 2) continue;
    final latest = attempts.last;
    final latestSucceeded =
        latest.tasteBalance == 0 ||
        (latest.rating != null && latest.rating! >= 4.0);
    if (!latestSucceeded) continue;

    final hasClearPriorAttempt = attempts.take(attempts.length - 1).any((
      prior,
    ) {
      final improvedTaste =
          latest.tasteBalance == 0 &&
          prior.tasteBalance != null &&
          prior.tasteBalance != 0;
      final improvedRating =
          latest.rating != null &&
          prior.rating != null &&
          prior.rating! < latest.rating!;
      return improvedTaste || improvedRating;
    });
    if (hasClearPriorAttempt) {
      final beanLabel = latest.beanName?.trim();
      final methodLabel = latest.methodName.trim();
      if (beanLabel != null && beanLabel.isNotEmpty && methodLabel.isNotEmpty) {
        candidates.add(latest);
      }
    }
  }

  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final winner = candidates.first;
  return DiaryDialInFact(
    beanName: winner.beanName!.trim(),
    methodName: winner.methodName.trim(),
  );
}

/// Finds previous-year memories from the diary's loaded full history.
///
/// Like the weekly recap, this assumes the complete diary is in memory. If the
/// timeline becomes paginated, this lookup must move to the DAO.
List<DiaryEntry> onThisDay(List<DiaryEntry> all, DateTime today) {
  final localToday = today.toLocal();
  final matches = all.where((entry) {
    final createdAt = entry.createdAt.toLocal();
    return createdAt.year < localToday.year &&
        createdAt.month == localToday.month &&
        createdAt.day == localToday.day;
  }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return matches;
}
