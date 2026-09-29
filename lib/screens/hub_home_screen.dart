import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart'; // Ensure this import is correct
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/design_tokens.dart'; // Import design tokens for AppRadius
import '../utils/app_logger.dart'; // Import AppLogger
import '../utils/blog_launcher.dart';
import '../utils/app_material_symbols.dart';
import '../widgets/account_avatar_inline.dart';
import '../widgets/coffee_journey_card.dart';
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
          _HubSection(
            title: l10n.hubSectionYourCoffee,
            children: [
              _HubListTile(
                identifier: 'brewDiary',
                label: l10n.brewdiary,
                icon: Icons.library_books,
                title: l10n.brewdiary,
                subtitle: l10n.hubBrewDiarySubtitle,
                onTap: () {
                  context.router.push(BrewDiaryRoute());
                },
              ),
              _HubListTile(
                identifier: 'stats',
                label: l10n.brewStats,
                icon: Icons.bar_chart,
                title: l10n.brewStats,
                subtitle: l10n.hubBrewStatsSubtitle,
                onTap: () {
                  context.router.push(StatsRoute());
                },
              ),
              _HubListTile(
                identifier: 'calculator',
                label: l10n.extractionCalcTitle,
                icon: Icons.calculate_outlined,
                title: l10n.extractionCalcTitle,
                subtitle: l10n.hubBrewCalculatorSubtitle,
                onTap: () {
                  context.router.push(ExtractionCalculatorRoute());
                },
              ),
              _HubListTile(
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
          _HubSection(
            title: l10n.explore,
            children: [
              _HubListTile(
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
              _HubListTile(
                identifier: 'roasters',
                label: l10n.roastersCatalogTitle,
                icon: Icons.store_outlined,
                title: l10n.roastersCatalogTitle,
                subtitle: l10n.hubRoastersSubtitle,
                onTap: () {
                  context.router.push(const RoastersRoute());
                },
              ),
              _HubListTile(
                identifier: 'blog',
                label: l10n.blogTitle,
                iconWidget: const NewsModeIcon(),
                title: l10n.blogTitle,
                subtitle: l10n.hubBlogSubtitle,
                onTap: () => openBlog(source: 'hub'),
              ),
            ],
          ),
          _HubSection(
            title: l10n.account,
            children: [_buildAccountTile(context, l10n)],
          ),
          _HubSection(
            title: l10n.hubSectionApp,
            children: [
              _HubListTile(
                identifier: 'settings',
                label: l10n.settings,
                icon: Icons.settings,
                title: l10n.settings,
                isCompact: true,
                onTap: () {
                  context.router.push(SettingsRoute());
                },
              ),
              _HubListTile(
                identifier: 'help',
                label: l10n.helpAndFAQ,
                icon: Icons.help_outline,
                title: l10n.helpAndFAQ,
                isCompact: true,
                onTap: () {
                  context.router.push(const HelpHomeRoute());
                },
              ),
              _HubListTile(
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

  Widget _buildAccountTile(BuildContext context, AppLocalizations l10n) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        final isLoggedIn = session != null && !session.user.isAnonymous;

        if (isLoggedIn) {
          return _HubListTile(
            identifier: 'account',
            label: l10n.account,
            icon: Icons.account_circle,
            leading: const AccountAvatarInline(size: 24),
            title: l10n.account,
            subtitle: l10n.hubAccountSubtitle,
            onTap: () {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              AppLogger.debug(
                'Navigating to AccountRoute with userId: $userId',
              );
              if (userId != null) {
                context.router.push(AccountRoute(userId: userId));
              }
            },
          );
        }

        return _HubListTile(
          identifier: 'signIn',
          label: l10n.signInCreate,
          icon: Icons.login,
          title: l10n.signInCreate,
          subtitle: l10n.hubSignInCreateSubtitle,
          onTap: () => AuthenticationService.promptSignIn(
            context,
            source: 'hub',
            title: l10n.signInCreate,
            bodyText: l10n.hubSignInCreateSubtitle,
          ),
        );
      },
    );
  }
}

class _HubSection extends StatelessWidget {
  const _HubSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.base,
              AppSpacing.sm,
              AppSpacing.base,
              AppSpacing.xs,
            ),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: children),
        ],
      ),
    );
  }
}

class _HubListTile extends StatelessWidget {
  const _HubListTile({
    required this.identifier,
    required this.label,
    required this.title,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.leading,
    this.subtitle,
    this.isCompact = false,
  });

  final String identifier;
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      identifier: identifier,
      label: label,
      child: ListTile(
        dense: isCompact,
        visualDensity: isCompact ? VisualDensity.compact : null,
        leading: leading ?? iconWidget ?? Icon(icon),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
