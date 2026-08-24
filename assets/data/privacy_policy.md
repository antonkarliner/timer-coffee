# Privacy Policy for Timer.Coffee

Last Updated: 25.08.2026

1. INTRODUCTION

Timer.Coffee respects your privacy and is committed to handling your data responsibly. This Privacy Policy explains what data we collect, how we use it, how long we keep it, and how you can request deletion when you use the Timer.Coffee mobile app.

2. DATA COLLECTION AND USAGE

In plain language, we collect the data we need to keep your brews and recipes saved, sync your content across devices, run optional features like profiles and notifications, and understand when something is broken.

a. Account and Authentication Data

We use account data to sign you in, keep you signed in, securely fetch recipe and sync data from Supabase, and let you start with the app before you decide whether to create a full account.

- If you do not already have a session, the app may create an anonymous Supabase account for your device so the app can securely fetch recipe and sync data from Supabase without exposing the product to the same level of abuse risk as a fully unauthenticated public flow.
- We also use this anonymous account flow to improve the experience if you later decide to sign up, because your existing data can be carried forward instead of making you start over.
- If you later sign in with email, Apple, or Google, some data created under the anonymous account may be migrated to your signed-in account so you do not lose it.
- Depending on the sign-in method you use, we may process your Supabase user ID, email address, display name, provider-specific identifier, sign-in timestamps, and basic account metadata so authentication and sync work correctly.

b. Profile Data

We use profile data so your account can show a name and picture inside the app.

- If you use profile features, we store your display name and profile picture URL in our user profile records so the app can display your profile consistently across devices.
- If you upload a profile picture, the image file is stored in Supabase Storage and linked to your profile.
- Profile content, including display names and uploaded profile pictures, may be checked by automated moderation providers to reduce abuse and inappropriate content.

c. Brew, Recipe, Bean, and Preference Data

This is the core data of the product. We store it so the app can remember your brewing history, sync your content, and restore it when you switch devices.

- Brew statistics and brew events, such as recipe ID, brewing method, water amount, country of origin (country level only, derived from your IP address at the time of the brew), timestamps, and related identifiers, so your brewing history and aggregate stats work. The country is displayed publicly in the Pulse feed alongside the recipe name; no city or sub-national location is stored or shown.
- If you use the built-in extraction calculator and choose to save a result, we store the TDS (total dissolved solids) percentage and calculated extraction yield percentage you entered alongside the related brew statistic, so you can review your extraction results later and sync them across your devices. Saving a result is optional and only happens if you take that action.
- For each brew or diary entry, we may store the water temperature, optional taste feedback (sour, balanced, or bitter), and the entry source (whether the entry came from a timer-guided brew or was entered manually), so you can review and compare your brews later.
- Brew diary content, such as notes, custom tags you add to an entry, grind size, bean links, favorite or marked state, and sync metadata, so you can keep personal brewing records.
- Recipes, recipe localizations, and recipe steps, such as amounts, temperatures, brew times, descriptions, visibility state, and moderation flags, so custom recipes can be saved and synced.
- Bean records, such as roaster, bean name, origin, variety, tasting notes, processing method, elevation, harvest date, roast date, region, roast level, grind size, cupping score, notes, farmer, farm, package weight, favorite state, cover photo URL, and sync metadata, so you can track and reuse your bean information.
- Recipe preferences, such as favorites, last-used timestamps, slider positions, custom amounts, and custom grind size, so the app can remember how you like to brew.
- Recipe import events, recording your anonymized user identifier, the source recipe identifier, and a timestamp when you import a recipe shared by another user, so creators can see how many people have imported their public recipes.
- Recipe provenance, recording the original creator's user identifier on recipes you import or copy from another user, so the original author can be credited if the recipe is later shared publicly. This reference is removed automatically if the original author deletes their account.
- Roaster suggestions, if you choose to help add a roaster that is not yet in our database. When you submit a roaster's website (and optionally its Instagram handle or city) from a bean you logged, we store that suggestion linked to your account, which may be anonymous, and use it to verify the roaster and add it to our shared roaster catalog. The website you submit may be fetched and analyzed by our systems and third-party AI providers as part of that review. Please do not submit information you do not want used for this purpose.

d. Notifications and Live Activities

We use this data only if you enable these optional features.

- If you enable mobile notifications, we may store your push token and related device metadata, such as device type, device model, app version, locale, last-used timestamps, and token metadata so notifications can be sent to the right device and maintained over time.
- If you use notification preferences, we may store your quiet hours and notification preference settings so the app knows what you want to receive.
- To schedule local reminders such as a once-per-bean prompt to write a review after about five brews with the same beans, we count brews per bean locally on your device and store a timestamp of when the reminder was scheduled on the bean record. For signed-in users this timestamp is synced with your other bean data so the reminder is not repeated on another device.
- If you use iOS Live Activities, we may store session data needed to run that feature, such as recipe ID, recipe name, activity identifiers and tokens, step durations, step descriptions, start and end times, session status, and related delivery events.

e. AI-Assisted Features and Content Processing

We use AI tools mainly to save you manual work, such as reading a coffee bag label for you instead of making you type every field by hand.

- Timer.Coffee uses third-party AI providers, which may include Groq, Google Gemini or Vertex AI, and OpenAI, to support coffee label or bean recognition, content moderation, and certain translation or notification-processing features.
- For coffee label or bean recognition, submitted images are sent to these providers so they can extract bean information for you.
- We currently do not write the submitted recognition images to our main application tables as part of normal operation.
- During a camera-based AI scan in the mobile app, you can explicitly choose to keep the photos. If you opt in, only the final camera photos you confirm are copied locally into your device's Photos or Gallery. This local copy is separate from the temporary image processing used for AI recognition and from the optional bean cover photo upload to Supabase Storage available to signed-in users. Timer.Coffee does not gain permission to later read or browse the copies saved to your photo library.
- We do store recognition usage metadata, such as the user ID, invocation timestamp, and token or usage counters, so we can operate the feature, enforce limits, and understand usage.
- Diagnostic or platform logs may include limited processing information, such as response-format summaries, truncated text where needed, errors, and operational metadata, so we can debug failures and investigate abuse without storing raw recognition results in routine logs.
- If you upload a profile picture, that image is intentionally stored as part of the profile feature and is separate from temporary recognition input.
- If you upload a cover photo for a bean record, the image is compressed on your device and stored in Supabase Storage. The resulting URL is saved in your bean record and syncs across your devices. This feature is only available to signed-in, non-anonymous users.
- When you tap "Translate" (or "Translate all reviews") on a public bean review, the review text is sent to OpenAI to detect its source language and produce a translation in your current app language. Translations are cached on our servers and reused for any reader requesting the same language, so each (review, language) pair is only sent to OpenAI once. Editing your review invalidates the cached translations for that review.
- If you choose AI recipe review while creating or editing a recipe, Timer.Coffee sends structured recipe data to an AI provider so the app can check and correct scalable coffee and water amount formatting. This may include the recipe name, brewing method, coffee and water amounts, water temperature, grind size, short description, step text, step durations, app locale, source-language hint, and local validation issues. This happens only for signed-in users after you enable the option and accept the consent notice.
- If you consent to diagnostics for AI recipe review, we may store private diagnostic records containing source and corrected step templates, locale and language hints, validation issues, provider and model details, token or usage metadata, timestamps, and an anonymized or pseudonymous user reference. We use these records to debug failures, improve recipe creation, enforce limits, and investigate abuse. These diagnostics are not exposed to public clients.
- Because AI-assisted features may involve third-party processing and diagnostic logging, you should avoid submitting sensitive personal data unless it is necessary for the feature you are using.

f. Location and Regionalization Data

- To localize pricing, content, or availability, we may infer your country or broad region from your IP address through server-side or client-side geolocation services.

g. Anonymous Usage Analytics

We collect anonymous usage analytics so we can understand which features people actually use, where the brewing flow drops off, and how donation behavior relates to usage patterns. This data helps us improve the app without knowing who you are.

- The app collects anonymous event data such as brew starts and completions, bean additions, bean review interactions (creating, editing, deleting, and translating reviews), recipe creation and sharing, collection interactions and sharing, screen views, roaster profile views and taps on a roaster's external links (such as their website or social media), taps that open our blog (only which in-app entry point you used), donation funnel interactions, onboarding and first-steps journey progress, notification engagement (which in-app reminders were scheduled, delivered, opened, or cancelled — never their content), brew diary usage such as filters and searches performed (never the search text), entry edits, and exports of your own brew notes (only which kind of export you chose and how many entries it covered, never the notes themselves), and impressions of and interactions with in-app "moments" (small surprise-and-delight touches such as celebratory cards and seasonal banners). No personal information such as your name, email, or account ID is included in analytics events.
- Each installation is identified by a randomly generated ID that is not linked to your Supabase account or any other identifying information. A random session ID is generated each time you open the app.
- Events are buffered on-device and sent in batches to a Supabase Edge Function. Your IP address is stripped server-side before storage.
- Analytics events are organized into three categories — brewing analytics, bean analytics, and general usage analytics — each of which you can enable or disable independently in the app's Settings screen. All three categories are enabled by default.
- We can also disable all analytics collection remotely via a server-side feature flag, without requiring an app update.
- Raw analytics events are retained for 90 days and then automatically deleted. Pre-aggregated daily metrics that contain no device-level identifiers may be retained indefinitely.
- In regions where our backend is blocked, the app automatically routes through a reverse proxy to keep working. To understand how many users rely on this, the app records an anonymous connection event noting only whether the session connected directly or through the proxy, plus the platform (iOS, Android, or web). At most one such event is recorded per device per day. These events contain no user ID, account information, or location.

h. Data Export Requests

We let you export a copy of your own data as a self-serve way to exercise your right to access it (see Section 7).

- From Settings, you can request an export of your data by entering a destination email address. We email a 6-digit confirmation code to that address to confirm you control it; this only confirms the destination inbox and does not sign you in or change your account.
- Once you enter the correct code, we assemble your export by combining data stored on your device with data stored on our servers, and email a download link to the same address.
- The export includes your brew history and statistics, your coffee beans, your recipe preferences, your own custom recipes (including their steps and localizations), your public profile, and your bean reviews and review replies. It does not include the app's built-in recipe catalog or other shared reference content.
- The export is a zip file containing a JSON file with the complete data, several CSV files (brews, beans, reviews, and custom recipes) you can open in a spreadsheet, and a README describing the contents.
- The zip file is kept in a private location on our servers, not publicly accessible. The download link we email you expires after 1 hour, and the file itself is automatically deleted from our servers a few hours after it is created.
- To run this feature, we temporarily store a record of your export request: the destination email address you entered, a one-way cryptographic hash of the confirmation code (never the code itself), the number of attempts made to enter the code, and timestamps. This record is used only to enforce the checks below and is automatically deleted after 25 hours.
- To prevent abuse, we limit export requests to 3 per account and 3 per destination email address within any 24-hour period.
- The confirmation code only proves you control the destination inbox; it does not change whose data is exported. The data included in an export is always the data belonging to the account you are signed into when you make the request, so entering someone else's email address as the destination cannot be used to obtain their data.
- We use Resend to send the confirmation code and download link emails.

3. COOKIES

The mobile app is not a browser-based product, so browser cookies are not part of how it works.

4. SECURITY

We use commercially reasonable measures to protect your data. However, no method of transmission over the internet or electronic storage is completely secure, and we cannot guarantee absolute security.

5. THIRD-PARTY SERVICES

We rely on other providers for parts of the app that we do not run ourselves. For example:

- Supabase for authentication, database storage, Edge Functions, and file storage
- Firebase Cloud Messaging for push delivery when notifications are enabled
- Apple and Google for sign-in, if you choose those sign-in methods
- AI providers such as Groq, Google, and OpenAI for the AI-assisted features described above
- Resend for sending transactional emails, such as data export confirmation codes and download links

These providers may process data on our behalf so the feature you asked for actually works.

6. DATA RETENTION AND DELETION

- We retain account, sync, and content data for as long as your account remains active or as long as needed to provide the service. We do this so your data is still there when you come back.
- You can delete your account from within the app or by contacting support@timer.coffee.
- When you delete your account, we delete profile data, bean data, recipe preferences, recipes, user stats, and push token records associated with your account. Bean cover photo files stored in Supabase Storage are also removed as part of this process.
- Some analytics and usage records, including brew statistics, AI-recognition invocation records, and AI recipe-review diagnostic records, may be retained in anonymized form by replacing your user ID with a non-identifying placeholder. We keep these records to measure product usage, debug and improve recipe creation, and operate the service without keeping them tied to you.
- If you request a data export (Section 2h), we keep the request record, including the destination email address and a hashed confirmation code, for 25 hours to enforce abuse limits, and we automatically delete the exported file from storage a few hours after it is created.
- We may retain limited information where required for legal, security, fraud-prevention, or accounting reasons.

7. USER RIGHTS

Depending on your location, you may have rights regarding your personal data, including the right to access, correct, or delete your data. To exercise these rights, please contact support@timer.coffee. You can also self-serve a full export of your own data at any time from Settings in the app, without needing to contact support — see Section 2h for details.

8. CHANGES TO OUR PRIVACY POLICY

We may update this Privacy Policy from time to time. We will post any updated version in the app or on our website. Changes become effective when posted unless stated otherwise.

9. CONTACT US

For any questions or clarifications regarding this Privacy Policy, please contact us at support@timer.coffee.

10. HOW TO CONTACT THE APPROPRIATE AUTHORITY

If you believe Timer.Coffee has not handled your privacy concerns appropriately, you may contact your local data protection authority.

11. TRADEMARKS

All trademarks, service marks, trade names, trade dress, product names, and logos appearing in the app are the property of their respective owners.
