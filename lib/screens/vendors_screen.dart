import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vendor_model.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class VendorsScreen extends StatefulWidget {
  const VendorsScreen({Key? key}) : super(key: key);

  @override
  _VendorsScreenState createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.explore),
      ),
      body: FutureBuilder<List<VendorModel>>(
        future: recipeProvider.fetchAllActiveVendors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No vendors found"));
          }
          // Filter out the vendor with vendorId = "timercoffee"
          final vendors = snapshot.data!
              .where((vendor) => vendor.vendorId != "timercoffee")
              .toList();

          if (vendors.isEmpty) {
            return const Center(child: Text("No vendors found"));
          }

          return ListView.builder(
            itemCount: vendors.length,
            itemBuilder: (BuildContext context, int index) {
              VendorModel vendor = vendors[index];
              return ListTile(
                title: Text(vendor.vendorName),
                onTap: () {
                  context.router.push(
                    VendorsRecipeListRoute(vendorId: vendor.vendorId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
