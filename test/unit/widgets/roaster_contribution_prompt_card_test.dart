import 'package:coffee_timer/services/roaster_contribution_service.dart';
import 'package:coffee_timer/widgets/roaster_contribution/contribution_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('defers eligibility until the route transition completes', (
    tester,
  ) async {
    var checkCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  transitionDuration: const Duration(seconds: 1),
                  pageBuilder: (_, _, _) => Scaffold(
                    body: RoasterContributionPromptCard(
                      roaster: 'Pending Roaster',
                      eligibilityChecker: (roaster) async {
                        checkCount++;
                        return RoasterContributionEligibility.ineligible;
                      },
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(checkCount, 0);

    await tester.pump(const Duration(milliseconds: 500));
    expect(checkCount, 0);

    await tester.pump(const Duration(milliseconds: 501));
    expect(checkCount, 1);
  });

  testWidgets('checks immediately on an already completed route', (
    tester,
  ) async {
    var checkCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoasterContributionPromptCard(
            roaster: 'Pending Roaster',
            eligibilityChecker: (roaster) async {
              checkCount++;
              return RoasterContributionEligibility.ineligible;
            },
          ),
        ),
      ),
    );

    expect(checkCount, 1);
  });

  testWidgets('waits for an unknown-roaster lookup before checking', (
    tester,
  ) async {
    var checkCount = 0;
    var profileLookupCompleted = false;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return RoasterContributionPromptCard(
                roaster: 'Pending Roaster',
                profileLookupCompleted: profileLookupCompleted,
                eligibilityChecker: (roaster) async {
                  checkCount++;
                  return RoasterContributionEligibility.ineligible;
                },
              );
            },
          ),
        ),
      ),
    );

    expect(checkCount, 0);

    rebuild(() => profileLookupCompleted = true);
    await tester.pump();

    expect(checkCount, 1);
  });

  testWidgets('skips eligibility for a known roaster', (tester) async {
    var checkCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoasterContributionPromptCard(
            roaster: 'Known Roaster',
            profileLookupCompleted: true,
            isKnownRoaster: true,
            eligibilityChecker: (roaster) async {
              checkCount++;
              return RoasterContributionEligibility.ineligible;
            },
          ),
        ),
      ),
    );

    expect(checkCount, 0);
  });
}
