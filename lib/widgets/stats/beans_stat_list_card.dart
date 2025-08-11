import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Generic card that shows a capped preview list and a "Show more" modal for full lists.
class BeansStatListCard<T> extends StatelessWidget {
  const BeansStatListCard({
    Key? key,
    required this.label,
    required this.leadingIcon,
    this.countFuture,
    required this.previewListFuture,
    required this.fullListFuture,
    required this.itemBuilder,
    required this.emptyText,
  }) : super(key: key);

  final String label;
  final Widget leadingIcon;
  final Future<int> Function(BuildContext)? countFuture;
  final Future<List<T>> Function(BuildContext) previewListFuture;
  final Future<List<T>> Function(BuildContext) fullListFuture;
  final Widget Function(BuildContext, T, {bool isPreview}) itemBuilder;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingIcon,
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<int?>(
                    future: countFuture != null
                        ? countFuture!(context)
                        : Future.value(null),
                    builder: (ctx, snapshot) {
                      final countWidget = snapshot.connectionState ==
                              ConnectionState.waiting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (snapshot.hasError
                              ? Text(': —',
                                  style: textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold))
                              : (snapshot.data == null
                                  ? const SizedBox.shrink()
                                  : Text(': ${snapshot.data}',
                                      style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold))));
                      return Text.rich(
                        TextSpan(
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: label),
                            if (countFuture != null) const TextSpan(text: ' '),
                            if (countFuture != null)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: countWidget,
                              ),
                          ],
                        ),
                        softWrap: true,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Preview list
            FutureBuilder<List<T>>(
              future: previewListFuture(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (snapshot.hasError) {
                  return Text('—', style: textTheme.bodyMedium);
                }

                final preview = snapshot.data ?? <T>[];

                if (preview.isEmpty) {
                  // Empty preview: show subdued empty text
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(emptyText,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor)),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...preview.map((t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: itemBuilder(context, t, isPreview: true),
                        )),
                    const SizedBox(height: 4),
                    // Decide whether to show "Show more" by fetching full list length
                    FutureBuilder<List<T>>(
                      future: fullListFuture(context),
                      builder: (context, fullSnapshot) {
                        if (fullSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          // While checking full length we skip showing button to avoid layout shift
                          return const SizedBox.shrink();
                        }
                        if (fullSnapshot.hasError) {
                          return const SizedBox.shrink();
                        }
                        final full = fullSnapshot.data ?? <T>[];
                        if (full.length > preview.length) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _openFullModal(context),
                              child:
                                  Text(AppLocalizations.of(context)!.showMore),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFullModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return _FullListModal<T>(
              label: label,
              leadingIcon: leadingIcon,
              countFuture: countFuture,
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

class _FullListModal<T> extends StatelessWidget {
  const _FullListModal({
    Key? key,
    required this.label,
    required this.leadingIcon,
    this.countFuture,
    required this.fullListFuture,
    required this.itemBuilder,
    required this.emptyText,
    required this.scrollController,
  }) : super(key: key);

  final String label;
  final Widget leadingIcon;
  final Future<int> Function(BuildContext)? countFuture;
  final Future<List<T>> Function(BuildContext) fullListFuture;
  final Widget Function(BuildContext, T, {bool isPreview}) itemBuilder;
  final String emptyText;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // AppBar-like header (styled to match the card header; no divider)
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 8.0, 8.0),
            child: Row(
              children: [
                leadingIcon,
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<int?>(
                    future: countFuture != null
                        ? countFuture!(context)
                        : Future.value(null),
                    builder: (ctx, snapshot) {
                      final countWidget = snapshot.connectionState ==
                              ConnectionState.waiting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (snapshot.hasError
                              ? Text(': —',
                                  style: textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold))
                              : (snapshot.data == null
                                  ? const SizedBox.shrink()
                                  : Text(': ${snapshot.data}',
                                      style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold))));
                      return Text.rich(
                        TextSpan(
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: label),
                            if (countFuture != null) const TextSpan(text: ' '),
                            if (countFuture != null)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: countWidget,
                              ),
                          ],
                        ),
                        softWrap: true,
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<T>>(
              future: fullListFuture(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final list = snapshot.data ?? <T>[];
                if (list.isEmpty) {
                  return Center(
                    child: Text(emptyText,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor)),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: itemBuilder(context, item, isPreview: false),
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
