import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:flutter/material.dart';

import 'stats_row.dart';

class BeansStatRow<T> extends StatelessWidget {
  const BeansStatRow({
    super.key,
    required this.identifier,
    required this.icon,
    required this.label,
    required this.countFuture,
    required this.fullListFuture,
    required this.itemBuilder,
    required this.emptyText,
  });

  final String identifier;
  final IconData icon;
  final String label;
  final Future<int> Function(BuildContext) countFuture;
  final Future<List<T>> Function(BuildContext) fullListFuture;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: countFuture(context),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final count = snapshot.data ?? 0;
        final canOpenList = !isLoading && !snapshot.hasError && count > 0;

        return StatsRow(
          identifier: identifier,
          icon: icon,
          label: label,
          value: snapshot.hasError ? '—' : count.toString(),
          mutedValue: !canOpenList,
          isLoading: isLoading,
          onTap: canOpenList ? () => _openFullModal(context, count) : null,
        );
      },
    );
  }

  void _openFullModal(BuildContext context, int count) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return _FullListModal<T>(
              label: label,
              icon: icon,
              count: count,
              fullListFuture: fullListFuture,
              itemBuilder: itemBuilder,
              emptyText: emptyText,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _FullListModal<T> extends StatefulWidget {
  const _FullListModal({
    required this.label,
    required this.icon,
    required this.count,
    required this.fullListFuture,
    required this.itemBuilder,
    required this.emptyText,
    required this.scrollController,
  });

  final String label;
  final IconData icon;
  final int count;
  final Future<List<T>> Function(BuildContext) fullListFuture;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyText;
  final ScrollController scrollController;

  @override
  State<_FullListModal<T>> createState() => _FullListModalState<T>();
}

class _FullListModalState<T> extends State<_FullListModal<T>> {
  // Fetch once per opening so dragging the sheet does not reload the list.
  late final Future<List<T>> _fullList = widget.fullListFuture(context);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedBody = AppTextStyles.body.copyWith(color: colorScheme.outline);

    // Transparent so the list shows the sheet's own colour: the framework
    // drag handle sits above this widget, and a painted surface here would
    // leave the handle strip a different shade in dark mode.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.xs,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: AppIconSize.medium,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(child: Text(widget.label, style: AppTextStyles.title)),
                const SizedBox(width: AppSpacing.sm),
                Text(widget.count.toString(), style: mutedBody),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<T>>(
              future: _fullList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: AppStroke.focus,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.failedToLoadData),
                  );
                }
                final list = snapshot.data ?? <T>[];
                if (list.isEmpty) {
                  return Center(child: Text(widget.emptyText, style: mutedBody));
                }
                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.sm,
                      ),
                      child: widget.itemBuilder(context, list[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
