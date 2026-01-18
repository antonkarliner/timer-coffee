import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_filter_options.dart';
import 'package:coffee_timer/services/coffee_beans_filter_service.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'roaster_selection_dialog.dart';
import 'origin_selection_dialog.dart';

/// Modal bottom sheet dialog for filtering coffee beans.
///
/// This dialog provides a comprehensive filtering interface including:
/// - Roaster selection (multiple choice)
/// - Origin selection (multiple choice, filtered by selected roasters)
/// - Favorites-only toggle
/// - Reset filters functionality
///
/// Uses the CoffeeBeansFilterOptions model and CoffeeBeansFilterService
/// for data management and filtering logic.
class CoffeeBeansFilterDialog extends StatefulWidget {
  /// Current filter options to initialize the dialog with
  final CoffeeBeansFilterOptions initialFilterOptions;

  /// Service for handling filter operations
  final CoffeeBeansFilterService filterService;

  const CoffeeBeansFilterDialog({
    Key? key,
    required this.initialFilterOptions,
    required this.filterService,
  }) : super(key: key);

  @override
  State<CoffeeBeansFilterDialog> createState() =>
      _CoffeeBeansFilterDialogState();
}

class _CoffeeBeansFilterDialogState extends State<CoffeeBeansFilterDialog> {
  late CoffeeBeansFilterOptions _tempFilterOptions;
  List<String> _availableRoasters = [];
  List<String> _availableOrigins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tempFilterOptions = widget.initialFilterOptions;
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    try {
      // Load available roasters and origins
      _availableRoasters =
          await widget.filterService.fetchAvailableRoasters(context);

      // Load origins based on current roaster selection
      await _updateOrigins();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Updates the available origins based on selected roasters
  Future<void> _updateOrigins() async {
    try {
      _availableOrigins = await widget.filterService.fetchOriginsForRoasters(
        context,
        _tempFilterOptions.selectedRoasters,
      );

      // Filter current selected origins to only include those still available
      final updatedSelectedOrigins = _tempFilterOptions.selectedOrigins
          .where((origin) => _availableOrigins.contains(origin))
          .toList();

      setState(() {
        _tempFilterOptions = _tempFilterOptions.copyWith(
          selectedOrigins: updatedSelectedOrigins,
        );
      });
    } catch (e) {
      // Handle error silently, keep current state
    }
  }

  Future<void> _showRoasterSelectionDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => RoasterSelectionDialog(
        selectedRoasters: _tempFilterOptions.selectedRoasters,
        availableRoasters: _availableRoasters,
      ),
    );

    if (result != null) {
      setState(() {
        _tempFilterOptions = _tempFilterOptions.copyWith(
          selectedRoasters: result,
        );
      });
      // Update origins when roasters change
      await _updateOrigins();
    }
  }

  Future<void> _showOriginSelectionDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => OriginSelectionDialog(
        selectedOrigins: _tempFilterOptions.selectedOrigins,
        availableOrigins: _availableOrigins,
      ),
    );

    if (result != null) {
      setState(() {
        _tempFilterOptions = _tempFilterOptions.copyWith(
          selectedOrigins: result,
        );
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _tempFilterOptions = CoffeeBeansFilterOptions.empty;
    });
    _updateOrigins();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return SafeArea(
        child: Container(
          height: 200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Roaster Selection
            ListTile(
              title: Row(
                children: [
                  Text(
                    '${loc.roaster}: ',
                    style: AppTextStyles.caption,
                  ),
                  Expanded(
                    child: Text(
                      _tempFilterOptions.selectedRoasters.isEmpty
                          ? loc.all
                          : _tempFilterOptions.selectedRoasters.join(', '),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              onTap: _showRoasterSelectionDialog,
            ),

            // Origin Selection
            ListTile(
              title: Row(
                children: [
                  Text(
                    '${loc.origin}: ',
                    style: AppTextStyles.caption,
                  ),
                  Expanded(
                    child: Text(
                      _tempFilterOptions.selectedOrigins.isEmpty
                          ? loc.all
                          : _tempFilterOptions.selectedOrigins.join(', '),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              onTap: _showOriginSelectionDialog,
            ),

            const SizedBox(height: 8),

            // Favorites Only Toggle
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Row(
                children: [
                  Text(
                    loc.showFavoritesOnly,
                    style: AppTextStyles.caption,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Checkbox(
                        value: _tempFilterOptions.isFavoriteOnly,
                        onChanged: (value) => setState(() {
                          _tempFilterOptions = _tempFilterOptions.copyWith(
                            isFavoriteOnly: value ?? false,
                          );
                        }),
                        activeColor:
                            Theme.of(context).brightness == Brightness.light
                                ? const Color(0xff8e2e2d)
                                : const Color(0xffc66564),
                        checkColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () => setState(() {
                _tempFilterOptions = _tempFilterOptions.copyWith(
                  isFavoriteOnly: !_tempFilterOptions.isFavoriteOnly,
                );
              }),
            ),

            const SizedBox(height: 16),
            const SizedBox(height: 8),

            // Action Buttons
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 16.0,
              children: [
                AppTextButton(
                  label: loc.resetFilters,
                  onPressed: _resetFilters,
                ),
                AppElevatedButton(
                  label: loc.apply,
                  onPressed: () {
                    Navigator.pop(context, _tempFilterOptions);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
