# Help screen discovery audit

Date: 2026-07-28
App: Timer.Coffee 3.8.1 (build 451), current local checkout
Device: iPhone 17 Pro simulator, iOS 26.5
Locale/theme: English, system theme

## Scope and caveats

This is a read-only product-content pass based on the running iOS app. I walked
the main brewing, bean, diary, analytics, recipe-building, discovery, settings,
and support surfaces and captured screenshots for possible reuse.

The checkout already contained unrelated local changes before the audit,
including in-progress Brew Diary export work. The app was launched as-is, so
screenshots reflect that current local state. I did not enable notification,
camera, or photo permissions; sign out; delete anything; save a new recipe; or
complete a brew. A temporary recipe draft was created only to inspect the steps
editor and was discarded without saving.

## Recommended Help structure

The Help screen should be task-led rather than a catalogue of every screen.
These categories and articles cover the questions the running app naturally
raises.

### 1. Start your first brew

Suggested articles:

- **Find a recipe** — Browse collections, favorites, the most recently used
  recipe, or recipes grouped by brewing method.
- **Adjust a recipe before brewing** — Select a bean; change coffee and water
  amounts, grind size, and water temperature; expand the recipe summary; use
  the previous grind setting shown for the selected bean.
- **Follow the guided timer** — The app starts with a preparation screen, then
  shows the current timed step, a countdown ring, the next instruction, and a
  pause/resume control.
- **Audio and manual step controls** — Audio can be muted from Preparation.
  Manual back/skip arrows are an Advanced / Beta setting.
- **After the timer finishes** — Explain that the post-brew record is where
  users can evaluate and annotate the brew. Avoid promising background or Live
  Activity behavior until it has been verified with notifications enabled.

Useful screenshots:

- `19-brewing-home.png`
- `20-recipe-details.png`
- `21-brew-preparation.png`
- `22-brew-timer-paused.png`

### 2. Coffee beans and inventory

Suggested articles:

- **Add a bag of coffee** — The manual form requires roaster, name, and origin.
  Users can optionally add a cover photo and details for processing, flavor,
  quality/measurements, inventory, dates, grind preferences, and notes.
- **Scan a bag with AI** — AI Scan is the primary alternative to manual entry.
  This article should explain what the user should photograph and what still
  needs review before saving; camera/photo permission behavior still needs a
  separate verified pass.
- **Organize your beans** — Search; switch grid/list view; sort; filter; mark
  favorites; and enter edit mode. The library shows total inventory remaining.
- **Understand a bean page** — Roast age, amount left and approximate brews
  remaining, origin/variety/farm, terroir, processing, roast level, tasting
  notes, personal notes, reviews, and brews made with the coffee.
- **Keep inventory accurate** — The bean page includes a direct “Set to zero”
  action. The exact inventory changes caused by completing or editing a brew
  should be verified in a dedicated state-change pass before documenting them.

Useful screenshots:

- `15-my-beans.png`
- `16-bean-details-top.png`
- `17-bean-inventory-details.png`
- `18-add-beans.png`

### 3. Brew Diary and dialing in

This deserves the most substantial Help coverage because it contains several
powerful features that are not self-evident.

Suggested articles:

- **Find a past brew** — Timeline search plus filters for rating, bookmarks, and
  brewing method.
- **Read the timeline** — Month summary, brew count, average rating, streak,
  “On this day,” weekly digest, and date-grouped brew cards.
- **Edit a brew record** — Bean link, dose/water and computed ratio, grind,
  temperature, extraction, taste result, rating, notes, tags, bookmark, share,
  and “Brew again.”
- **Dial in a coffee** — The By bean tab groups brews by coffee, shows “Dialing
  in” / “Dialed in” state, evaluation coverage, and the number of brewing
  methods used.
- **Track progress by method** — A bean journey plots evaluated attempts for a
  selected brewing method, highlights the best cup, and lets users edit the
  latest rating.
- **Compare two brews** — Select two attempts to compare dose, water, ratio,
  grind, temperature, extraction, taste, and rating side by side. The comparison
  marks the better taste result and best cup.
- **Export or add diary entries** — The current checkout displays document
  export and plus actions on the Diary and per-bean cards. Their final labels
  and exact share/export result should be verified after the in-progress export
  work settles.

Useful screenshots:

- `05-brew-diary.png`
- `06-brew-entry-detail.png`
- `07-brew-entry-notes-tags.png`
- `08-brew-diary-by-bean.png`
- `09-bean-dial-in-progress.png`
- `10-brew-comparison.png`

### 4. Brew statistics and extraction

Suggested articles:

- **Read Brew Stats** — Choose Today, This Week, This Month, or a custom period.
  Personal stats include coffee volume, most-used recipes, beans used, new
  beans, origins, regions, and roasters; a separate section shows global
  activity.
- **Use the extraction calculator** — Choose filter or espresso, enter dose,
  beverage weight, water used, and a refractometer TDS reading, or start from a
  brew in history.
- **Extraction, TDS, and strength** — Prefer a short Help overview that points
  back to the calculator’s existing in-screen learning cards rather than
  duplicating all their copy.

Observed calculator guidance:

- Extraction yield is the portion of ground coffee dissolved into the cup.
  Roughly 18–22% is presented as a common balanced range, with taste taking
  priority over the number.
- TDS is the concentration/strength of the liquid and requires a coffee
  refractometer. The screen gives typical ranges of 1.15–1.45% for filter coffee
  and 8–12% for espresso.
- Strength and extraction are independent: grind and time mainly move
  extraction, while dose and water mainly move strength.
- The beverage-weight estimate subtracts about 2 g of retained water per gram
  of coffee; weighing the actual beverage is more accurate.

Useful screenshots:

- `11-brew-stats-month.png`
- `12-extraction-calculator.png`

### 5. Create and manage recipes

Suggested articles:

- **Create a recipe** — Stage one defines name, description, method, coffee,
  water, temperature, grind, and total brew time.
- **Build recipe steps** — Stage two separates Preparation from timed Brew
  Steps. Steps have descriptions and duration, can be added/deleted, and can be
  reordered.
- **Verify a recipe with AI** — Optional verification is described in-app as a
  check that scaled amounts adjust correctly. The Help article should also make
  the data-sharing boundary clear before this feature is promoted.
- **Copy, share, and favorite recipes** — These actions appear on recipe
  details. User-created/imported recipes are managed from “Your recipes” in
  More.

Useful screenshots:

- `20-recipe-details.png`
- `23-recipe-steps-editor.png`

### 6. Explore the coffee community

Suggested articles:

- **Pulse** — A live summary and recent feed of broadly located, anonymized brew
  activity, including recipe and relative time.
- **Find a roaster** — Search the directory or filter it by country.
- **Roaster pages and bean reviews** — Roaster pages show location, community
  bag count, and reviews. The running app explains that a user must log a bag
  from that roaster before writing a review.

Useful screenshots:

- `13-pulse-live-feed.png`
- `14-roaster-profile.png`

### 7. Personalize the app and manage data

Suggested articles:

- **Appearance and formats** — Theme, language, app icon, and date/time format.
- **Choose what appears on Home** — Enable/disable brewing methods and recipe
  collections.
- **Notifications** — Explain the master toggle and permission troubleshooting
  only after a permission-enabled test pass.
- **Privacy and analytics** — Separate controls exist for brewing, bean, and
  general usage analytics.
- **Export your data** — Settings describes this as a download of brews, beans,
  and recipes.
- **Account and support** — Profile edit, sign out, and account deletion are on
  Account. Website, source code, Instagram, support, privacy policy, content
  rules, and version/build are on About.

Useful screenshots:

- `02-settings-overview.png`
- `03-settings-date-time.png`
- `04-settings-privacy-advanced.png`
- `24-about-support.png`

## What should be prominent on Help Home

Recommended first-screen order:

1. Start your first brew
2. Adjust a recipe and select a bean
3. Brew Diary: notes, ratings, and bookmarks
4. Dial in a bean and compare brews
5. Add and manage coffee beans
6. Create your own recipe
7. Extraction calculator
8. Settings, privacy, and data export
9. Contact support

“Pulse,” Brew Stats, roaster discovery, app icons, and detailed extraction
theory are valuable but should sit below the primary tasks or inside their
categories.

## Product/content observations to resolve before writing final articles

- Several icon-only actions have no descriptive accessibility label in the
  audit tree, including Diary export/add and some recipe actions. Help copy
  should not have to compensate for unclear controls; final labels should be
  confirmed in the UI first.
- Notification behavior, iOS permission recovery, background timing, and Live
  Activities were not verified because notifications were disabled and no
  permission prompt was accepted.
- AI Scan was not opened because that would require camera/photo permission.
- AI recipe verification was not enabled, so its output and failure states were
  not verified.
- Completing a brew was intentionally avoided to prevent creating a real diary
  entry. Existing completed brews were used to inspect the resulting record,
  editing, dial-in, and comparison surfaces.
- The current bean sample displays an elevation value as `12501350m`, which
  looks malformed. It should not appear in instructional screenshots.
- The hidden Help implementation is category/article based and synced into the
  app, so the structure above maps naturally to the existing model without
  requiring a new content format.

## Screenshot folders

- `screenshots/cropped/` — preferred review/use copies, cropped to the simulated
  device.
- `screenshots/raw/` — original Simulator-window captures.

The purple pointer glow is part of the simulator-control capture and should be
removed only when final screenshots are selected; preserving it in this audit
keeps the source captures unaltered apart from cropping.

## Phase 1 verification follow-up

Date: 2026-07-28
Device: fresh iPhone 17 Pro simulator, iOS 26.5

The follow-up started a fresh Simulator and attempted to launch the current
checkout in release mode. Flutter rejected the target with:

```text
Releasemode is not supported by iPhone 17 Pro.
```

A debug build was launched only for read-only inspection. No screenshots were
retained, no permissions were granted, and no brew, recipe, bean, account, or
deletion action was intentionally performed. The Simulator accessibility
inspection hung without returning a UI tree, so the planned state-changing
verification could not be completed reliably.

As a result, the Help launch must currently omit, or avoid making specific
claims about:

- post-brew persistence and automatic inventory changes;
- camera/photo permission recovery and AI bag-scan results;
- AI recipe-review input, output, failures, and data-sharing boundary;
- notification permission recovery, background timing, Live Activities,
  Dynamic Island, and Android ongoing notifications;
- cross-device account merge/sync behavior;
- the final Diary export/add contract while that work remains in progress.

This is an evidence decision, not evidence that those features are broken.
They can be added to Help after a release-capable, controllable device pass
verifies the user-visible behavior. Final or replacement Help screenshots must
come from release mode; debug captures are not an acceptable substitute.
