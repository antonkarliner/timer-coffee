import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_router.gr.dart';
import '../models/recipe_collection_model.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_collection_provider.dart';
import '../providers/recipe_provider.dart';
import '../services/analytics_service.dart';
import '../services/collection_new_badge_service.dart';
import '../theme/design_tokens.dart';
import '../utils/icon_utils.dart';
import '../widgets/favorite_button.dart';
import '../widgets/smart_back_button.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

@RoutePage()
class CollectionDetailScreen extends StatefulWidget {
  final String collectionId;

  const CollectionDetailScreen({
    super.key,
    @PathParam('collectionId') required this.collectionId,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  Future<_CollectionView>? _future;
  String? _loadedForLocale;

  Future<_CollectionView> _load(String locale) async {
    final badgeService = context.read<CollectionNewBadgeService>();
    final hadNewBadge = badgeService.hasNew(widget.collectionId);
    final provider = context.read<RecipeCollectionProvider>();
    final collection = await provider.getCollectionById(
      widget.collectionId,
      locale,
    );
    final recipes = await provider.fetchRecipesFor(widget.collectionId, locale);
    if (collection != null) {
      AnalyticsService.instance.track(
        'collection_detail_viewed',
        properties: {
          'collection_id': widget.collectionId,
          'locale': locale,
          'recipe_count': recipes.length,
          'had_new_badge': hadNewBadge,
        },
      );
    }
    await badgeService.markViewed(widget.collectionId);
    return _CollectionView(collection: collection, recipes: recipes);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // Watch the locale so we reload contents when the user changes language.
    final locale = context.watch<RecipeProvider>().currentLocale.languageCode;
    if (_future == null || _loadedForLocale != locale) {
      _loadedForLocale = locale;
      _future = _load(locale);
    }
    return Scaffold(
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: FutureBuilder<_CollectionView>(
          future: _future,
          builder: (context, snapshot) {
            final c = snapshot.data?.collection;
            if (c == null) {
              return Text(loc.loadingEllipsis);
            }
            return Row(
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
              ],
            );
          },
        ),
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: loc.collectionShareTooltip,
              icon: Icon(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? CupertinoIcons.share
                    : Icons.share,
              ),
              onPressed: () => _shareCollection(buttonContext),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_CollectionView>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final view = snapshot.data;
          if (view == null || view.collection == null) {
            return Center(child: Text(loc.collectionEmpty));
          }
          final recipes = view.recipes;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (view.collection!.description != null &&
                  view.collection!.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    view.collection!.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: recipes.isEmpty
                    ? Center(child: Text(loc.collectionEmpty))
                    : ListView.builder(
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return ListTile(
                            leading: getIconByBrewingMethod(
                              recipe.brewingMethodId,
                            ),
                            title: Text(recipe.name),
                            trailing: FavoriteButton(recipeId: recipe.id),
                            onTap: () {
                              AnalyticsService.instance.track(
                                'collection_recipe_tapped',
                                properties: {
                                  'collection_id': widget.collectionId,
                                  'recipe_id': recipe.id,
                                  'brewing_method_id': recipe.brewingMethodId,
                                  'locale': locale,
                                  'recipe_index': index,
                                  'recipe_count': recipes.length,
                                },
                              );
                              context.router.push(
                                RecipeDetailRoute(
                                  brewingMethodId: recipe.brewingMethodId,
                                  recipeId: recipe.id,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shareCollection(BuildContext buttonContext) async {
    AnalyticsService.instance.track(
      'collection_shared',
      properties: {
        'collection_id': widget.collectionId,
        'source': 'collection_detail',
      },
    );
    final url = 'https://app.timer.coffee/collections/${widget.collectionId}';
    final box = buttonContext.findRenderObject() as RenderBox?;
    final mediaQuery = MediaQuery.of(buttonContext);
    Rect? origin;
    if (box != null && box.hasSize) {
      if (mediaQuery.size.shortestSide >= 768) {
        final center = Offset(
          mediaQuery.size.width / 2,
          mediaQuery.size.height / 2,
        );
        origin = Rect.fromCenter(center: center, width: 1, height: 1);
      } else {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    }
    await SharePlus.instance.share(
      ShareParams(text: url, sharePositionOrigin: origin),
    );
  }
}

class _CollectionView {
  final RecipeCollectionModel? collection;
  final List<RecipeModel> recipes;
  _CollectionView({required this.collection, required this.recipes});
}
