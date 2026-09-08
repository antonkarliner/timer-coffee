import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> popupMap() => {
    'id': 1,
    'content': 'Update available',
    'locale': 'en',
    'created_at': '2026-09-08T10:00:00Z',
    'platform': 'all',
  };

  group('LaunchPopupModel campaign fields', () {
    test('campaign fields are null when keys are absent', () {
      final popup = LaunchPopupModel.fromMap(popupMap());

      expect(popup.hookType, isNull);
      expect(popup.goalAmountUsd, isNull);
      expect(popup.progressAmountUsd, isNull);
      expect(popup.campaignEndsAt, isNull);
      expect(popup.isCampaign, isFalse);
      expect(popup.isCampaignActive, isFalse);
    });

    test('campaign fields are null when values are explicitly null', () {
      final popup = LaunchPopupModel.fromMap({
        ...popupMap(),
        'hook_type': null,
        'goal_amount_usd': null,
        'progress_amount_usd': null,
        'campaign_ends_at': null,
      });

      expect(popup.hookType, isNull);
      expect(popup.goalAmountUsd, isNull);
      expect(popup.progressAmountUsd, isNull);
      expect(popup.campaignEndsAt, isNull);
      expect(popup.isCampaign, isFalse);
      expect(popup.isCampaignActive, isFalse);
    });

    test('parses a full active campaign', () {
      final popup = LaunchPopupModel.fromMap({
        ...popupMap(),
        'hook_type': 'coffee_day',
        'goal_amount_usd': 1000,
        'progress_amount_usd': 425.5,
        'campaign_ends_at': '2999-10-01T12:00:00+02:00',
      });

      expect(popup.hookType, 'coffee_day');
      expect(popup.goalAmountUsd, 1000.0);
      expect(popup.progressAmountUsd, 425.5);
      expect(popup.campaignEndsAt, DateTime.utc(2999, 10, 1, 10));
      expect(popup.isCampaign, isTrue);
      expect(popup.isCampaignActive, isTrue);
    });

    test('an expired campaign is inactive', () {
      final popup = LaunchPopupModel.fromMap({
        ...popupMap(),
        'hook_type': 'black_friday',
        'campaign_ends_at': '2000-01-01T00:00:00Z',
      });

      expect(popup.isCampaign, isTrue);
      expect(popup.isCampaignActive, isFalse);
    });

    test('a campaign without an end date is active', () {
      final popup = LaunchPopupModel.fromMap({
        ...popupMap(),
        'hook_type': 'yearly_recap',
        'campaign_ends_at': null,
      });

      expect(popup.isCampaign, isTrue);
      expect(popup.isCampaignActive, isTrue);
    });

    test('an unknown hook type is not a campaign', () {
      final popup = LaunchPopupModel.fromMap({
        ...popupMap(),
        'hook_type': 'future_campaign',
      });

      expect(popup.hookType, isNull);
      expect(popup.isCampaign, isFalse);
    });

    test('parses numeric amounts from int, double, and String values', () {
      final intAmount = LaunchPopupModel.fromMap({
        ...popupMap(),
        'goal_amount_usd': 100,
      });
      final doubleAmount = LaunchPopupModel.fromMap({
        ...popupMap(),
        'goal_amount_usd': 100.5,
      });
      final stringAmount = LaunchPopupModel.fromMap({
        ...popupMap(),
        'goal_amount_usd': '100.75',
      });

      expect(intAmount.goalAmountUsd, 100.0);
      expect(doubleAmount.goalAmountUsd, 100.5);
      expect(stringAmount.goalAmountUsd, 100.75);
    });

    test('invalid amounts and campaign end values yield null', () {
      final popup = LaunchPopupModel.fromMap({
        ...popupMap(),
        'goal_amount_usd': 'not a number',
        'progress_amount_usd': Object(),
        'campaign_ends_at': 'not a date',
      });

      expect(popup.goalAmountUsd, isNull);
      expect(popup.progressAmountUsd, isNull);
      expect(popup.campaignEndsAt, isNull);
    });
  });
}
