import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart'; // Ensure this import is correct
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/design_tokens.dart'; // Import design tokens for AppRadius
import '../utils/blog_launcher.dart';
import '../utils/app_material_symbols.dart';
import '../services/settings_analytics.dart';
import '../widgets/account/account_entry_tile.dart';
import '../widgets/coffee_journey_card.dart';
import '../widgets/for_you_card.dart';
import '../widgets/hub_list_tile.dart';
import '../widgets/settings/settings_list.dart';
import '../services/authentication_service.dart';
import 'pulse_screen.dart';

// Added import
// Import http package
// Import for RecipeCreationScreen
// Import AppDatabase and Recipe

@RoutePage()
class HubHomeScreen extends StatefulWidget {
  const HubHomeScreen({super.key});

  @override
  State<HubHomeScreen> createState() => _HubHomeScreenState();
}

class _HubHomeScreenState extends State<HubHomeScreen> {
  @override
  void initState() {
    super.initState();
    _refreshFcmTokenForSignedInUser();
  }

  Future<void> _refreshFcmTokenForSignedInUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      await AuthenticationService.registerFcmTokenForCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight +
              AppSpacing.base,
        ),
        children: [
          const CoffeeJourneyCard(location: JourneyCardLocation.hub),
          const ForYouCard(),
          SettingsSection(
            header: l10n.hubSectionYourCoffee,
            children: [
              HubListTile(
                identifier: 'brewDiary',
                label: l10n.brewdiary,
                icon: Icons.library_books,
                title: l10n.brewdiary,
                subtitle: l10n.hubBrewDiarySubtitle,
                onTap: () {
                  context.router.push(BrewDiaryRoute());
                },
              ),
              HubListTile(
                identifier: 'stats',
                label: l10n.brewStats,
                icon: Icons.bar_chart,
                title: l10n.brewStats,
                subtitle: l10n.hubBrewStatsSubtitle,
                onTap: () {
                  context.router.push(StatsRoute());
                },
              ),
              HubListTile(
                identifier: 'calculator',
                label: l10n.extractionCalcTitle,
                icon: Icons.calculate_outlined,
                title: l10n.extractionCalcTitle,
                subtitle: l10n.hubBrewCalculatorSubtitle,
                onTap: () {
                  context.router.push(ExtractionCalculatorRoute());
                },
              ),
              HubListTile(
                identifier: 'userRecipes',
                label: l10n.hubUserRecipesTitle,
                icon: Icons.bookmarks_outlined,
                title: l10n.hubUserRecipesTitle,
                subtitle: l10n.hubUserRecipesSubtitle,
                onTap: () {
                  context.router.push(const UserRecipeManagementRoute());
                },
              ),
            ],
          ),
          SettingsSection(
            header: l10n.explore,
            children: [
              HubListTile(
                identifier: 'pulse',
                label: l10n.pulseTitle,
                iconWidget: const VitalSignsIcon(),
                title: l10n.pulseTitle,
                subtitle: l10n.hubPulseSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PulseScreen()),
                  );
                },
              ),
              HubListTile(
                identifier: 'roasters',
                label: l10n.roastersCatalogTitle,
                icon: Icons.storefront_outlined,
                title: l10n.roastersCatalogTitle,
                subtitle: l10n.hubRoastersSubtitle,
                onTap: () {
                  context.router.push(const RoastersRoute());
                },
              ),
              HubListTile(
                identifier: 'blog',
                label: l10n.blogTitle,
                iconWidget: const NewsModeIcon(),
                title: l10n.blogTitle,
                subtitle: l10n.hubBlogSubtitle,
                onTap: () => openBlog(source: 'hub'),
              ),
            ],
          ),
          SettingsSection(
            header: l10n.account,
            children: [const AccountEntryTile(source: AccountEntrySource.hub)],
          ),
          SettingsSection(
            header: l10n.hubSectionApp,
            children: [
              HubListTile(
                identifier: 'settings',
                label: l10n.settings,
                icon: Icons.settings,
                title: l10n.settings,
                isCompact: true,
                onTap: () {
                  context.router.push(SettingsRoute());
                },
              ),
              HubListTile(
                identifier: 'help',
                label: l10n.helpAndFAQ,
                icon: Icons.help_outline,
                title: l10n.helpAndFAQ,
                isCompact: true,
                onTap: () {
                  context.router.push(const HelpHomeRoute());
                },
              ),
              HubListTile(
                identifier: 'info',
                label: l10n.about,
                icon: Icons.info_outline,
                title: l10n.about,
                isCompact: true,
                onTap: () {
                  context.router.push(InfoRoute());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

}
