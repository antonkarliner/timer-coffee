// lib/screens/vendors_recipe_list_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recipe_model.dart';
import '../models/vendor_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import '../utils/icon_utils.dart';

@RoutePage()
class VendorsRecipeListScreen extends StatefulWidget {
  final String vendorId;

  const VendorsRecipeListScreen({
    Key? key,
    @PathParam('vendorId') required this.vendorId,
  }) : super(key: key);

  @override
  _VendorsRecipeListScreenState createState() =>
      _VendorsRecipeListScreenState();
}

class _VendorsRecipeListScreenState extends State<VendorsRecipeListScreen>
    with WidgetsBindingObserver {
  Future<List<RecipeModel>> recipesForVendor = Future.value([]);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var initialLocale = Provider.of<Locale>(context, listen: false);

      if (kIsWeb) {
        var recipeProvider =
            Provider.of<RecipeProvider>(context, listen: false);
        var tempLocale = const Locale('av'); // Temporary locale for simulation
        await recipeProvider.setLocale(tempLocale);
        await Future.delayed(const Duration(milliseconds: 10));
        await recipeProvider.setLocale(initialLocale);
      }

      // After setting the locale, fetch the recipes
      recipesForVendor = Provider.of<RecipeProvider>(context, listen: false)
          .fetchRecipesForVendor(widget.vendorId);

      // Trigger a rebuild now that the actual recipesForVendor Future is set
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _navigateToRecipeDetail(RecipeModel recipe) {
    context.router.push(VendorRecipeDetailRoute(
      recipeId: recipe.id,
      vendorId: recipe.vendorId!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: FutureBuilder<String>(
          future: Provider.of<RecipeProvider>(context, listen: false)
              .fetchVendorName(widget.vendorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
            final imageUrl = isDarkTheme
                ? "https://timercoffeeapp.fra1.cdn.digitaloceanspaces.com/${widget.vendorId}/logo-dark.png"
                : "https://timercoffeeapp.fra1.cdn.digitaloceanspaces.com/${widget.vendorId}/logo.png";

            return Center(
              child: Image.network(
                imageUrl,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  if (isDarkTheme) {
                    return Image.network(
                      "https://timercoffeeapp.fra1.cdn.digitaloceanspaces.com/${widget.vendorId}/logo.png",
                      height: 80,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(snapshot.data ?? "Unknown Vendor");
                      },
                    );
                  }
                  return Text(snapshot.data ?? "Unknown Vendor");
                },
              ),
            );
          },
        ),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<RecipeModel>>(
                future: recipesForVendor,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final recipes = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return ListTile(
                        leading: getIconByBrewingMethod(recipe.brewingMethodId),
                        title: Text(recipe.name),
                        onTap: () {
                          _navigateToRecipeDetail(recipe);
                        },
                        trailing: FavoriteButton(recipeId: recipe.id),
                      );
                    },
                  );
                }),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 200.0),
            child: FutureBuilder<VendorModel?>(
              future: Provider.of<RecipeProvider>(context, listen: false)
                  .fetchVendorById(widget.vendorId),
              builder: (context, vendorSnapshot) {
                if (vendorSnapshot.hasData) {
                  final vendor = vendorSnapshot.data!;
                  return Column(
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            vendor.vendorName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child:
                            _buildRichText(context, vendor.vendorDescription),
                      ),
                    ],
                  );
                } else {
                  return const Text("Vendor information not available");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichText(BuildContext context, String text) {
    final RegExp linkRegExp = RegExp(r'\[(.*?)\]\((.*?)\)');
    final Iterable<RegExpMatch> matches = linkRegExp.allMatches(text);

    TextStyle defaultTextStyle = Theme.of(context).textTheme.bodyLarge!;
    List<TextSpan> spanList = [];

    int lastMatchEnd = 0;

    for (final match in matches) {
      final String precedingText = text.substring(lastMatchEnd, match.start);
      final String linkText = match.group(1)!;
      final String linkUrl = match.group(2)!;

      // Add preceding text span
      if (precedingText.isNotEmpty) {
        spanList.add(TextSpan(text: precedingText, style: defaultTextStyle));
      }

      // Add link text span
      spanList.add(TextSpan(
        text: linkText,
        style: defaultTextStyle.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (await canLaunchUrl(Uri.parse(linkUrl))) {
              await launchUrl(Uri.parse(linkUrl));
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last match
    if (lastMatchEnd < text.length) {
      spanList.add(TextSpan(
          text: text.substring(lastMatchEnd), style: defaultTextStyle));
    }

    return RichText(
      text: TextSpan(children: spanList),
    );
  }
}
