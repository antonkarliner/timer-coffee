# Timer.Coffee

[<img src="https://www.timer.coffee/assets/images/app-store-badge.webp" width="27%">](https://apple.co/42WfmtI) [<img src="https://www.timer.coffee/assets/images/google-play-badge.webp" width="30%">](https://play.google.com/store/apps/details?id=com.coffee.timer) [<img src="https://www.timer.coffee/assets/images/web-app-badge.webp" width="30%">](https://app.timer.coffee)

**Timer.Coffee now speaks 10 languages! Supported languages are: English, Spanish, Portuguese, German, French, Russian, Polish, Arabic, Chinese and Japanese. If you want to improve localizations, head to Localization for instructions.

Timer.Coffee is a free and open source app which can help you to brew great coffee. Currently supported brewing techniques are: Hario V60, Aeropress, Chemex, French Press, Kalita Wave, Wilfa Svart Pour Over, Origami Dripper. The app features more than 30 recipes with more on the way.

Please feel free to contribute. The easiest way to add a new recipe is to submit a PR (recipes can be found in assets/data), alternatively you can open an issue and add the recipe description there.

Current features include:

- Adjust the coffee or water amount in recipes to brew as much coffee as you wish.
- Mark recipes as favorites.
- Show last used recipe.
- Share your favorite recipes with friends.
- Turn on sound chime to infrom you about the next brewing step.

Coming soon:

- Tetsu Kasuya 4:6 brewing method for Hario V60
- Design upgrades
- More recipes!

If you find the app useful and you want to support the development, you can use [this link](https://www.buymeacoffee.com/timercoffee).

Enjoy your coffee!

![image](https://i.imgur.com/xN1b9gk.png)

## Localization

If you want to improve the localization for the language, you can find translated interface files under lib/l10n/ and translated recipe files under assets/data/[locale]. Feel free to submit a PR, please also explain the reason for the correction.

If you want to add a new localization, you need to the following:

1. Translate interface. Take lib/l10n/app_en.arb and translate the values. Upload the translated file to lib/l10n/ and name it app_<language_code>.arb, for example app_de.arb
2. Translate recipes. Take assets/data/en folder and translate values for all the JSON files except brewing_methods.json. Don't translate placeholders, such as <final_water_amount> or <final_coffee_amount>, don't translate values for "brewing_method_id", "brew_time" and "is_favorite". Don’t rename the files. Pay attention to decimal separators, it should always be decimal points, e.g. "0.6". Upload the translated files to assets/data/[new locale] folder.
3. Submit a PR.

A litte advice: it's okay to use the automatic translation (deepl, chatgpt, etc.) for the initial translation, but make sure to check for the readability and integrity and correct if needed. Also pay attention to placeholders and other translation rules.
