# Privacy Policy for Timer.Coffee

Last Updated: 20.11.2026

1. INTRODUCTION

Timer.Coffee respects your privacy and is committed to handling your data responsibly. This Privacy Policy explains what data we collect, how we use it, how long we keep it, and how you can request deletion when you use the Timer.Coffee mobile app and our website, including the roaster dashboard.

2. DATA COLLECTION AND USAGE

In plain language, we collect the data we need to keep your brews and recipes saved, sync your content across devices, run optional features like profiles and notifications, and understand when something is broken.

a. Account and Authentication Data

We use account data to sign you in, keep you signed in, securely fetch recipe and sync data from Supabase, and let you start with the app before you decide whether to create a full account.

- If you do not already have a session, the app may create an anonymous Supabase account for your device so the app can securely fetch recipe and sync data from Supabase without exposing the product to the same level of abuse risk as a fully unauthenticated public flow.
- We also use this anonymous account flow to improve the experience if you later decide to sign up, because your existing data can be carried forward instead of making you start over.
- If you later sign in with email, Apple, or Google, some data created under the anonymous account may be migrated to your signed-in account so you do not lose it.
- Depending on the sign-in method you use, we may process your Supabase user ID, email address, display name, provider-specific identifier, sign-in timestamps, and basic account metadata so authentication and sync work correctly.
- If your account has an email sign-in, the Account screen shows that email address. If you change it, you enter a new address, and we send a 6-digit code to your current address and another 6-digit code to the new address; you must enter both to confirm. Until both are confirmed, the requested new address is stored with your account as a pending change. Once confirmed, it becomes your sign-in email and the pending record is cleared; your account keeps the same account ID and all its data (nothing is moved or copied), and the previous address is no longer linked to the account, so signing in with it later would create a separate, new account.
- If you cannot access your current email address, a "Can't access…?" link opens your own email app with a pre-filled message to support@timer.coffee. The app does not put any email address in that message, and nothing is sent unless you send it.
- If you are signed in, you can link Google or Apple (Apple on iOS) to your existing account as an additional way to sign in. Linking keeps the same account ID and no data is moved. When you link, we store that provider's account identifier and the profile details the provider shares with us at sign-in, such as the email address and name associated with that Google or Apple account (for Apple this may be a private relay address). If that Google or Apple account already belongs to a different Timer.Coffee account, linking is refused and nothing changes on either account; we do not merge accounts.
- You can remove a linked Google or Apple sign-in from the Account screen, which deletes that provider's identity record from your account. The email sign-in cannot be removed this way, and an account's last remaining sign-in method can never be removed.

b. Profile Data

We use profile data so your account can show a name and picture inside the app.

- If you use profile features, we store your display name and profile picture URL in our user profile records so the app can display your profile consistently across devices.
- If you upload a profile picture, the image file is stored in Supabase Storage and linked to your profile. Removing your picture requests deletion of the stored image.
- Profile content, including display names and uploaded profile pictures, may be checked by automated moderation providers to reduce abuse and inappropriate content.

c. Brew, Recipe, Bean, and Preference Data

This is the core data of the product. We store it so the app can remember your brewing history, sync your content, and restore it when you switch devices.

- The app keeps a separate local database for each account. Older bean and diary entries whose owner cannot be determined stay on this device outside the active library, sync and export. They may therefore be absent from your library after an upgrade.
- Brew statistics and brew events, such as recipe ID, brewing method, water amount, country of origin (country level only, derived from your IP address at the time of the brew), timestamps, and related identifiers, so your brewing history and aggregate stats work. The country is displayed publicly in the Pulse feed alongside the recipe name; no city or sub-national location is stored or shown.
- If you use the built-in extraction calculator and choose to save a result, we store the TDS (total dissolved solids) percentage and calculated extraction yield percentage you entered alongside the related brew statistic, so you can review your extraction results later and sync them across your devices. Saving a result is optional and only happens if you take that action.
- For each brew or diary entry, we may store the water temperature, optional taste feedback (sour, balanced, or bitter), and the entry source (whether the entry came from a timer-guided brew or was entered manually), so you can review and compare your brews later.
- Brew diary content, such as notes, custom tags you add to an entry, grind size, bean links, favorite or marked state, and sync metadata, so you can keep personal brewing records.
- When you link a bean to a brew, we also store a copy of that bean's name and roaster on the brew entry itself. This is a snapshot of what the bean was called at the time, so the entry still says which coffee you brewed if you later delete the bean record. While the bean record still exists, the diary shows its current details, so correcting a typo in a bean's name updates your past brews too.
- When you delete a brew, bean, or recipe, the record is marked as deleted rather than erased immediately, and we store the time it was deleted. This is what lets your deletion sync to your other devices instead of the record reappearing from them.
- Recipes, recipe localizations, and recipe steps, such as amounts, temperatures, brew times, descriptions, visibility state, and moderation flags, so custom recipes can be saved and synced.
- Bean records, such as roaster, bean name, origin, variety, tasting notes, processing method, elevation, harvest date, roast date, region, roast level, grind size, cupping score, notes, farmer, farm, package weight, favorite state, cover photo reference, and sync metadata, so you can track and reuse your bean information.
- Recipe preferences, such as favorites, last-used timestamps, slider positions, custom amounts, and custom grind size, so the app can remember how you like to brew.
- Recipe import events, recording your anonymized user identifier, the source recipe identifier, and a timestamp when you import a recipe shared by another user, so creators can see how many people have imported their public recipes.
- Recipe provenance, recording the original creator's user identifier on recipes you import or copy from another user, so the original author can be credited if the recipe is later shared publicly. This reference is removed automatically if the original author deletes their account.
- Roaster suggestions, if you choose to help add a roaster that is not yet in our database. When you submit a roaster's website (and optionally its Instagram handle or city) from a bean you logged, we store that suggestion linked to your account, which may be anonymous, and use it to verify the roaster and add it to our shared roaster catalog. The website you submit may be fetched and analyzed by our systems and third-party AI providers as part of that review. Please do not submit information you do not want used for this purpose.
- Roaster page error reports, if you choose to report a problem with a roaster's page (for example a wrong city, a broken website, or a business that has closed). We store the kind of problem you picked, any corrected value and details you type, which roaster page it concerns, and a link to your account, which may be anonymous, so we can review the report and correct the page. When you report from our website instead of the app, no account is linked, and we store an email address only if you choose to give one so we can follow up. Please do not include personal information in the details.
- Roaster page claim requests, if you ask on our website to manage a roaster's page. We store the name, role, work email address, and optional message you submit, together with the roaster page you asked about, and use them to verify that you represent the business, to contact you about your request, and, if it is approved, to set up your roaster account. Our website's report and claim forms use Cloudflare Turnstile to block automated abuse; Cloudflare processes technical information about your browser for this check.

d. Notifications and Live Activities

We use this data only if you enable these optional features.

- If you enable mobile notifications, we may store your push token and related device metadata, such as device type, device model, app version, the app's language (and whether you chose it in Settings or it follows your device's language), last-used timestamps, and token metadata so notifications can be sent to the right device and maintained over time. We also store your approximate country (country level only, derived from your IP address) and your device's time zone with the push token, so that notifications reach you in your language, can be limited to the countries or regions they are relevant to, and can arrive at a suitable local time. No city or more precise location is stored.
- If you use notification preferences, we may store your quiet hours and notification preference settings so the app knows what you want to receive.
- To schedule local reminders such as a once-per-bean prompt to write a review after about five brews with the same beans, we count brews per bean locally on your device and store a timestamp of when the reminder was scheduled on the bean record. For signed-in users this timestamp is synced with your other bean data so the reminder is not repeated on another device.
- If you use iOS Live Activities, we may store session data needed to run that feature, such as recipe ID, recipe name, activity identifiers and tokens, step durations, step descriptions, start and end times, session status, and related delivery events.

e. AI-Assisted Features and Content Processing

We use AI tools mainly to save you manual work, such as reading a coffee bag label for you instead of making you type every field by hand.

- Timer.Coffee uses third-party AI providers, which may include Groq, Google Gemini or Vertex AI, OpenAI, Anthropic, and Z.ai, to support coffee label or bean recognition, content moderation, and certain translation or notification-processing features.
- For coffee label or bean recognition, the app creates a new image from the visible pixels and removes embedded camera metadata, including GPS tags, before sending it for recognition. Details visible in the picture itself are processed.
- We currently do not write the submitted recognition images to our main application tables as part of normal operation.
- During a camera-based AI scan in the mobile app, you can explicitly choose to keep the photos. If you opt in, only the final camera photos you confirm are copied locally into your device's Photos or Gallery. This local copy is separate from the temporary image processing used for AI recognition and from the optional bean cover photo upload to Supabase Storage available to signed-in users. This saving feature does not request photo-library browsing access, and Timer.Coffee does not use it to later read or browse the saved copies.
- We do store recognition usage metadata, such as the user ID, invocation timestamp, and token or usage counters, so we can operate the feature, enforce limits, and understand usage.
- Diagnostic or platform logs may include limited processing information, such as response-format summaries, truncated text where needed, errors, and operational metadata, so we can debug failures and investigate abuse without storing raw recognition results in routine logs.
- If you upload a profile picture, that image is intentionally stored as part of the profile feature and is separate from temporary recognition input.
- If you upload a cover photo for a bean record, the image is compressed on your device and stored in Supabase Storage. The bean record stores a reference to the image. The app requests a five-minute link to display it. Replacing or removing a cover queues the previous image for deletion. This feature is only available to signed-in, non-anonymous users.
- When you tap "Translate" (or "Translate all reviews") on a public bean review, the review text is sent to OpenAI to detect its source language and produce a translation in your current app language. Translations are cached on our servers and reused for any reader requesting the same language, so each (review, language) pair is only sent to OpenAI once. Editing your review invalidates the cached translations for that review.
- For bean records that sync to our servers, the text of four fields (origin, processing method, roast level and tasting notes) is sent to one of the third-party AI providers named above so it can be sorted into standard categories, such as a country code, "washed", "light" or "berry". Each distinct piece of text is sent once, on its own, without your account, any user identifier or the rest of the bean record. The resulting category is stored on our servers and reused for everyone who typed the same text. We use these categories to group and compare beans, for example on roaster pages, and to work out which coffees are similar to ones you have had. Please do not put personal information in these fields.
- If bean suggestions are available to you and switched on, we work out a short summary of your taste from the beans and brews that sync to our servers: how much of what you drink falls into each origin country, processing method, roast level and flavour family. We send that summary, an approximate country (taken from the roasters whose beans you log or, failing that, inferred from your IP address or language as described in Section 2f) and your app language to one of the third-party AI providers named above, together with a shortlist of coffees that roasters currently have in stock, described only by the same kinds of categories. The provider puts the shortlist in order and writes the short reason shown with each suggestion. A plain description of your taste categories is also sent to one of those providers to be turned into a list of numbers that we use to compare coffees. Neither request includes your name, email address, account or any user identifier, the names of your beans or roasters, your notes, or your individual brews.
- We store your suggestions on our servers, linked to your account (which may be anonymous), so they appear without being worked out again each time, along with any suggestion you mark as not for you. When you open a roaster's product page from a suggestion or from the "In stock now" list on a roaster page, we record which listing you opened, where in the app you opened it and when, linked to your account, so we can tell roasters how many visits came from Timer.Coffee. We do not pass your identity to the roaster.
- On the Your taste profile screen you can see the summary we work out from your beans and brews and adjust it: for any origin country, processing method, roast level or flavour family you can ask for it to be suggested more often, less often or never. We store each adjustment on our servers, linked to your account (which may be anonymous). Adjustments change your taste summary before it is used, so the summary sent to the AI provider as described above reflects them, and coffees matching something you set to never are left off the shortlist before anything is sent. You can clear an adjustment on the same screen at any time.
- You can switch bean suggestions off in Settings → Privacy & data. Doing so deletes your stored suggestions, the ones you dismissed and your taste-profile adjustments from our servers, and nothing further is sent to an AI provider for this feature.
- Listings shown in suggestions and on roaster pages are taken from roasters' public websites. Product photos are loaded directly from the roaster's own website, so that website receives your IP address and basic device information, as it would if you visited it. Opening a listing takes you to the roaster's website in an in-app browser, where the roaster's own privacy policy applies.
- Earlier versions of the app offered an optional AI recipe review, which sent the recipe you were creating or editing to an AI provider to check how its coffee and water amounts were written. This feature has been removed; recipe amounts are now checked by the app itself and are not sent to an AI provider.
- If you used that review and consented to diagnostics, we stored private diagnostic records containing source and corrected step templates, locale and language hints, validation issues, provider and model details, token or usage metadata, timestamps, and an anonymized or pseudonymous user reference. We keep these records only to improve how the app reads recipe amounts. They are not exposed to public clients and will be deleted no later than 9 April 2027.
- Because AI-assisted features may involve third-party processing and diagnostic logging, you should avoid submitting sensitive personal data unless it is necessary for the feature you are using.

f. Location and Regionalization Data

- To localize pricing, content, or availability, we may infer your country or broad region from your IP address through server-side or client-side geolocation services.

g. Anonymous Usage Analytics

We collect anonymous usage analytics so we can understand which features people actually use, where the brewing flow drops off, and how donation behavior relates to usage patterns. This data helps us improve the app without knowing who you are.

- The app collects anonymous event data such as brew starts and completions, bean additions, bean review interactions (creating, editing, deleting, and translating reviews), recipe creation and sharing, collection interactions and sharing, screen views, roaster profile views and taps on a roaster's external links (such as their website or social media), opening and sending a roaster page error report (only which kind of problem you chose and whether it was sent, never what you typed), taps on the link to claim a roaster page, taps that open our blog (only which in-app entry point you used), bean suggestions and roasters' in-stock lists (when they are shown and how many coffees they held, which listing you tapped, opened or dismissed and its position, whether you expanded the list or switched suggestions on or off and from where, and, when no suggestions could be shown, a short reason and an approximate country — never your taste summary), opening your taste profile (whether there was enough history to show a summary and how many adjustments you had) and changing an adjustment (which kind of category — origin, process, roast or flavour — whether you chose more, less, never or cleared it, and whether it saved — never which country, process, roast or flavour), donation funnel interactions, onboarding and first-steps journey progress, notification engagement (which reminder types you switched on or off, whether you allowed or declined the notification permission prompt and on which screen you were asked, and which in-app reminders were scheduled, delivered, opened, or cancelled — never their content), account sign-in changes (when you request, complete, or fail to complete a change of your account email, at which step it failed and a short reason such as an invalid or expired code or a rate limit, and when you link Google or Apple sign-in to your account, unlink it, or the linking fails, with which provider and a short reason such as the account already being used by another account), signing in to an account (which screen you started signing in from, which of Apple, Google, or email you chose, whether it completed, was cancelled, or failed, at which step it failed and a short reason such as an invalid code, whether it created a new account, and whether the data you created before signing in was moved to it — never your email address, code, or token), brew diary usage such as filters and searches performed (never the search text), entry edits, and exports of your own brew notes (only which kind of export you chose and how many entries it covered, never the notes themselves), impressions of and interactions with in-app "moments" (small surprise-and-delight touches such as celebratory cards and seasonal banners), when the app asks your device's app store to show its rating prompt (only that the request was made, whether the store reported it as available, and how many brews you had completed at the time; Apple or Google decide whether the prompt actually appears, and we never learn whether or how you rated the app), which settings you change and to what value (theme, language, date and time format, app icon, snow, step change alerts, which brewing methods appear on Home, and whether brewing or bean analytics are shared — never your general usage analytics choice), where in the app you opened Settings or your account from, profile edits and whether the change was accepted or rejected by moderation (never the name or the image), signing out and deleting your account (and whether a deletion failed), the steps of a data-export request (started, code sent, completed, or failed with a short reason — never the destination email address or the code), and which brewing-screen layout (classic or immersive) you use and when you change it and from which screen (Settings, the Preparation screen's Brewing menu, the one-time layout picker shown on the Play button, or a suggestion on the finish screen), and, if you choose to tell us why you switched back to the classic timer, your answer from a short fixed list of reasons such as "hard to read" or "I prefer the classic timer" (never free text). No personal information such as your name, email, or account ID is included in analytics events. New installs may also be automatically assigned one of the two brewing-screen layouts as their starting default, chosen at random, so we can compare how each performs; you can change your layout at any time from Settings → Brewing or the Preparation screen.
- Each installation is identified by a randomly generated ID that is not linked to your Supabase account or any other identifying information. A random session ID is generated each time you open the app.
- Turning off an analytics category also drops its unsent events. While enabled, events are buffered on-device and sent in batches to a Supabase Edge Function. Your IP address is stripped server-side before storage.
- Analytics events are organized into three categories — brewing analytics, bean analytics, and general usage analytics — each of which you can enable or disable independently in the app under Settings → Privacy & data. All three categories are enabled by default. General usage analytics also controls recap engagement and Gift Box referral tracking. Bean analytics controls referral tracking for bean listings.
- We can also disable all analytics collection remotely via a server-side feature flag, without requiring an app update.
- Raw analytics events are retained for 90 days and then automatically deleted. Pre-aggregated daily metrics that contain no device-level identifiers may be retained indefinitely.
- In regions where our backend is blocked, the app automatically routes through a reverse proxy to keep working. When general usage analytics are enabled, the app records an anonymous connection event noting only whether the session connected directly or through the proxy, plus the platform (iOS, Android, or web). At most one such event is recorded per device per day. These events contain no user ID, account information, or location.

h. Data Export Requests

We let you export a copy of your own data as a self-serve way to exercise your right to access it (see Section 7).

- From Settings → Privacy & data, you can request an export of your data by entering a destination email address. We email a 6-digit confirmation code to that address to confirm you control it; this only confirms the destination inbox and does not sign you in or change your account.
- Once you enter the correct code, we assemble your export by combining data stored on your device with data stored on our servers, and email a download link to the same address.
- The export includes your brew history and statistics, your coffee beans, your recipe preferences, your own custom recipes (including their steps and localizations), your public profile, your bean reviews and review replies, and, if you use bean suggestions, your stored suggestions, the ones you dismissed, your taste-profile adjustments and the record of roaster listings you opened. It does not include the app's built-in recipe catalog or other shared reference content.
- The export is a zip file containing a JSON file with the complete data, several CSV files (brews, beans, reviews, and custom recipes) you can open in a spreadsheet, and a README describing the contents.
- The zip file is kept in a private location on our servers, not publicly accessible. The download link we email you expires after 1 hour, and the file itself is automatically deleted from our servers a few hours after it is created.
- To run this feature, we temporarily store a record of your export request: the destination email address you entered, a one-way cryptographic hash of the confirmation code (never the code itself), the number of attempts made to enter the code, and timestamps. This record is used only to enforce the checks below and is automatically deleted after 25 hours.
- To prevent abuse, we limit export requests to 3 per account and 3 per destination email address within any 24-hour period.
- The confirmation code only proves you control the destination inbox; it does not change whose data is exported. The data included in an export is always the data belonging to the account you are signed into when you make the request, so entering someone else's email address as the destination cannot be used to obtain their data.
- We use Resend to send the confirmation code and download link emails.

i. Web Recipe Maker (Beta)

The recipe maker on our website turns recipe text you paste, such as notes or a video transcript, into a Timer.Coffee recipe. It is used on the recipe maker page and in the roaster dashboard. While it is in beta, access comes with sharing what you submit, so we can improve how Timer.Coffee turns text into recipes. Before your first use we show you a notice and ask you to agree to it; without agreeing, you cannot use the recipe maker. We record that you agreed, which version of the notice you agreed to, and when.

- What we keep: the text you paste, what the AI made of it (the intermediate and final results from each processing step, plus the AI provider and model used), and the recipe you save at the end, linked to your account so we can delete it when you ask. We don't store your name, email address or IP address with it.
- Keep it to the recipe: please don't paste personal details like names or contact information. We only need the recipe, and our AI providers only get the text you paste, never your name, email or account.
- What we do with it: we read submissions and test changes to the recipe maker on them. That includes sending them again to our AI providers, OpenAI and Google (Vertex AI), who already process your text to make the feature work.
- How long: submissions are kept for 12 months and then deleted automatically. They are also deleted if you delete your account.
- Removal: email support@timer.coffee to have your submissions deleted sooner.
- Submissions are stored privately on our servers and are not exposed to public clients. A recipe you save stays private unless you choose to publish it.

j. Roaster Pages, the Roaster Dashboard, and Connected AI Apps

Coffee roasters can manage their Timer.Coffee roaster page from the roaster dashboard on our website. This section explains what we handle for roasters, and what it means for app users who review a roaster's coffee.

- Roaster accounts: when we approve a request to manage a roaster page, we link the roaster's account (their work email address) to that page. We store the page details the roaster saves (such as the description, website, location, and social links), the logo they upload, recipes they create or publish, and replies they write to reviews, together with when these were changed.
- Reviews and replies: roasters see the reviews app users have posted about their coffee in the dashboard, including the rating, review text, the reviewer's public display name, and the date. These are the same public reviews shown in the app. A roaster's reply is shown publicly with the review.
- Link safety checks: links on roaster pages (the website, links in the description, and social links) are checked against Google Web Risk, a Google service that lists known unsafe websites, when a roaster saves them and again regularly afterwards. Only the link itself is sent to Google. If a link is flagged, we hide it from the page, keep a private record of the flagged link and when it was found, and email the roaster and our team.
- Connected AI apps: a roaster can connect an AI assistant, such as Claude or ChatGPT, to their roaster page. The roaster signs in on a Timer.Coffee page and chooses to allow the app. We store a record of that connection, including the app's name, the roaster account that allowed it, and when, and we issue the app access tokens tied to that roaster's account.
- What a connected app can access: only the data of the roaster page the roaster manages, namely its page details, ratings and reviews (including reviewers' public display names), reply drafts, pending page-detail suggestions, and recipes. A connected app cannot publish anything: replies it writes are saved as drafts and page-detail changes as suggestions, which we store with a note of which app made them until the roaster approves or discards them. Recipe text an app sends to draft a recipe is handled as described in Section 2i.
- Data shared with the AI app: whatever a connected app reads is sent to that app's provider (for example Anthropic for Claude or OpenAI for ChatGPT) and is handled under that provider's own privacy policy and the roaster's agreement with them. We do not control how the provider processes or keeps it.
- Disconnecting: a roaster can disconnect an app at any time from the roaster dashboard. Its access ends immediately.

3. COOKIES

The mobile app is not a browser-based product, so browser cookies are not part of how it works.

4. SECURITY

We use commercially reasonable measures to protect your data. However, no method of transmission over the internet or electronic storage is completely secure, and we cannot guarantee absolute security.

5. THIRD-PARTY SERVICES

We rely on other providers for parts of the app that we do not run ourselves. For example:

- Supabase for authentication, database storage, Edge Functions, and file storage
- Firebase Cloud Messaging for push delivery when notifications are enabled
- Apple and Google for sign-in, if you choose those sign-in methods
- AI providers such as Groq, Google, OpenAI, Anthropic, and Z.ai for the AI-assisted features described above
- Resend for sending transactional emails, such as data export confirmation codes and download links
- Google Web Risk for checking links on roaster pages (Section 2j)
- AI apps a roaster chooses to connect to their roaster page, such as Claude by Anthropic or ChatGPT by OpenAI, which receive the roaster page data they access (Section 2j)

These providers may process data on our behalf so the feature you asked for actually works.

6. DATA RETENTION AND DELETION

- We retain account, sync, and content data for as long as your account remains active or as long as needed to provide the service. We do this so your data is still there when you come back.
- You can delete your account from within the app or by contacting support@timer.coffee.
- When you delete your account, we delete profile data, bean data, recipe preferences, recipes, user stats, bean suggestions (including the ones you dismissed), taste-profile adjustments, and push token records associated with your account. Bean cover photo files stored in Supabase Storage are also removed as part of this process.
- Some analytics and usage records, including brew statistics, AI-recognition invocation records, the record of roaster listings you opened, and AI recipe-review diagnostic records, may be retained in anonymized form by replacing your user ID with a non-identifying placeholder. We keep these records to measure product usage, debug and improve recipe creation, and operate the service without keeping them tied to you. AI recipe-review diagnostic records are deleted no later than 9 April 2027.
- If you request a data export (Section 2h), we keep the request record, including the destination email address and a hashed confirmation code, for 25 hours to enforce abuse limits, and we automatically delete the exported file from storage a few hours after it is created.
- If you use the web recipe maker (Section 2i), we keep your submissions for 12 months and then delete them automatically, or sooner if you delete your account or ask us at support@timer.coffee. We keep the record of your agreement to the beta notice until you delete your account.
- For roaster pages (Section 2j), we keep a connected app's record until the roaster disconnects it or their account is deleted, keep reply drafts and page-detail suggestions until the roaster approves or discards them, and keep records of flagged links so our team can review them and restore a link that was flagged by mistake.
- We may retain limited information where required for legal, security, fraud-prevention, or accounting reasons.

7. USER RIGHTS

Depending on your location, you may have rights regarding your personal data, including the right to access, correct, or delete your data. To exercise these rights, please contact support@timer.coffee. You can also self-serve a full export of your own data at any time from Settings → Privacy & data in the app, without needing to contact support — see Section 2h for details.

8. CHANGES TO OUR PRIVACY POLICY

We may update this Privacy Policy from time to time. We will post any updated version in the app or on our website. Changes become effective when posted unless stated otherwise.

9. CONTACT US

For any questions or clarifications regarding this Privacy Policy, please contact us at support@timer.coffee.

10. HOW TO CONTACT THE APPROPRIATE AUTHORITY

If you believe Timer.Coffee has not handled your privacy concerns appropriately, you may contact your local data protection authority.

11. TRADEMARKS

All trademarks, service marks, trade names, trade dress, product names, and logos appearing in the app are the property of their respective owners.
