import 'package:flutter/material.dart';

/// Presentational tile used to display a quick beans-related statistic.
/// It defers data loading to the provided loader and shows the result.
class BeansStatTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<int> Function(BuildContext ctx, DateTime start, DateTime end)
      loader;
  final DateTime start;
  final DateTime end;

  const BeansStatTile({
    super.key,
    required this.label,
    required this.icon,
    required this.loader,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    // [dart.BeansStatTile.build()](lib/widgets/stats/beans_stat_tile.dart:1)
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FutureBuilder<int>(
                future: loader(context, start, end),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      '—',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      '0',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    );
                  }
                  final value = snapshot.data ?? 0;
                  return Text(
                    value.toString(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
