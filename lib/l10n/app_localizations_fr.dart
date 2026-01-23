// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Statistiques des grains';

  @override
  String get totalBeansBrewedLabel => 'Total de grains utilisés';

  @override
  String get newBeansTriedLabel => 'Nouveaux grains essayés';

  @override
  String get originsExploredLabel => 'Origines explorées';

  @override
  String get regionsExploredLabel => 'Europe';

  @override
  String get newRoastersDiscoveredLabel => 'Nouveaux torréfacteurs découverts';

  @override
  String get favoriteRoastersLabel => 'Torréfacteurs favoris';

  @override
  String get topOriginsLabel => 'Meilleures origines';

  @override
  String get topRegionsLabel => 'Meilleures régions';

  @override
  String get lastrecipe => 'Recette la plus récemment utilisée :';

  @override
  String get userRecipesTitle => 'Vos recettes';

  @override
  String get userRecipesSectionCreated => 'Créées par vous';

  @override
  String get userRecipesSectionImported => 'Importées par vous';

  @override
  String get userRecipesEmpty => 'Aucune recette trouvée';

  @override
  String get userRecipesDeleteTitle => 'Supprimer la recette ?';

  @override
  String get userRecipesDeleteMessage => 'Cette action est irréversible.';

  @override
  String get userRecipesDeleteConfirm => 'Supprimer';

  @override
  String get userRecipesDeleteCancel => 'Annuler';

  @override
  String get userRecipesSnackbarDeleted => 'Recette supprimée';

  @override
  String get hubUserRecipesTitle => 'Vos recettes';

  @override
  String get hubUserRecipesSubtitle =>
      'Voir et gérer les recettes créées et importées';

  @override
  String get hubAccountSubtitle => 'Gérer votre profil';

  @override
  String get hubSignInCreateSubtitle =>
      'Connectez-vous pour synchroniser les recettes et les préférences';

  @override
  String get hubBrewDiarySubtitle =>
      'Consultez votre historique de brassage et ajoutez des notes';

  @override
  String get hubBrewStatsSubtitle =>
      'Consultez les statistiques et tendances de brassage personnelles et mondiales';

  @override
  String get hubSettingsSubtitle =>
      'Modifiez les préférences et le comportement de l\'application';

  @override
  String get hubAboutSubtitle =>
      'Détails de l\'application, version et contributeurs';

  @override
  String get about => 'À propos';

  @override
  String get author => 'Auteur';

  @override
  String get authortext =>
      'L\'application Timer.Coffee a été créée par Anton Karliner, un passionné de café, spécialiste des médias et photojournaliste. J\'espère que cette application vous aidera à profiter de votre café. N\'hésitez pas à contribuer sur GitHub.';

  @override
  String get contributors => 'Contributeurs';

  @override
  String get errorLoadingContributors =>
      'Erreur de chargement des contributeurs';

  @override
  String get license => 'Licence';

  @override
  String get licensetext =>
      'Cette application est un logiciel libre : vous pouvez la redistribuer et/ou la modifier sous les termes de la GNU General Public License telle que publiée par la Free Software Foundation, soit la version 3 de la Licence, ou (à votre choix) toute version ultérieure.';

  @override
  String get licensebutton => 'Lire la GNU General Public License v3';

  @override
  String get website => 'Site Web';

  @override
  String get sourcecode => 'Code source';

  @override
  String get support => 'Achète un café au développeur';

  @override
  String get allrecipes => 'Toutes les recettes';

  @override
  String get favoriterecipes => 'Recettes favorites';

  @override
  String get coffeeamount => 'Quantité de café (g)';

  @override
  String get wateramount => 'Quantité d\'eau (ml)';

  @override
  String get watertemp => 'Température de l\'eau';

  @override
  String get grindsize => 'Taille de mouture';

  @override
  String get brewtime => 'Temps d\'infusion';

  @override
  String get recipesummary => 'Résumé de la recette';

  @override
  String get recipesummarynote =>
      'Remarque : ceci est une recette de base avec des quantités d\'eau et de café par défaut.';

  @override
  String get preparation => 'Préparation';

  @override
  String get brewingprocess => 'Processus d’infusion';

  @override
  String get step => 'Étape';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'secondes',
      one: 'seconde',
      zero: 'secondes',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Merci d\'utiliser Timer.Coffee ! Profitez de votre';

  @override
  String get coffeefact => 'Fait sur le café';

  @override
  String get home => 'Accueil';

  @override
  String get appversion => 'Version de l\'application';

  @override
  String get tipsmall => 'Acheter un petit café';

  @override
  String get tipmedium => 'Acheter un café moyen';

  @override
  String get tiplarge => 'Acheter un grand café';

  @override
  String get supportdevelopment => 'Soutenir le développement';

  @override
  String get supportdevmsg =>
      'Vos dons aident à couvrir les coûts de maintenance (comme les licences de développeur, par exemple). Ils me permettent également d\'essayer plus d\'appareils de brassage de café et d\'ajouter plus de recettes à l\'application.';

  @override
  String get supportdevtnx => 'Merci de considérer faire un don !';

  @override
  String get donationok => 'Merci !';

  @override
  String get donationtnx =>
      'J\'apprécie vraiment votre soutien ! Je vous souhaite beaucoup de bons brassages ! ☕️';

  @override
  String get donationerr => 'Erreur';

  @override
  String get donationerrmsg =>
      'Erreur lors du traitement de l\'achat, veuillez réessayer.';

  @override
  String get sharemsg => 'Découvrez cette recette :';

  @override
  String get finishbrew => 'Terminer';

  @override
  String get settings => 'Paramètres';

  @override
  String get settingstheme => 'Thème';

  @override
  String get settingsthemelight => 'Clair';

  @override
  String get settingsthemedark => 'Sombre';

  @override
  String get settingsthemesystem => 'Système';

  @override
  String get settingslang => 'Langue';

  @override
  String get sweet => 'Doux';

  @override
  String get balance => 'Équilibre';

  @override
  String get acidic => 'Acide';

  @override
  String get light => 'Léger';

  @override
  String get strong => 'Fort';

  @override
  String get slidertitle => 'Utilisez les curseurs pour ajuster le goût';

  @override
  String get whatsnewtitle => 'Quoi de neuf';

  @override
  String get whatsnewclose => 'Fermer';

  @override
  String get seasonspecials => 'Spéciaux de Saison';

  @override
  String get snow => 'Neige';

  @override
  String get noFavoriteRecipesMessage =>
      'Votre liste de recettes favorites est actuellement vide. Commencez à explorer et à brasser pour découvrir vos favoris !';

  @override
  String get explore => 'Explorer';

  @override
  String get dateFormat => 'd MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Journal de Brassage';

  @override
  String get brewdiarynotfound => 'Aucune entrée trouvée';

  @override
  String get beans => 'Grains';

  @override
  String get roaster => 'Torréfacteur';

  @override
  String get rating => 'Évaluation';

  @override
  String get notes => 'Notes';

  @override
  String get statsscreen => 'Statistiques du café';

  @override
  String get yourStats => 'Vos statistiques';

  @override
  String get coffeeBrewed => 'Café infusé :';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Recettes les plus utilisées :';

  @override
  String get globalStats => 'Statistiques globales';

  @override
  String get unknownRecipe => 'Recette inconnue';

  @override
  String get noData => 'Aucune donnée';

  @override
  String error(String error) {
    return 'Erreur : $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Quelqu\'un vient d\'infuser $recipeName';
  }

  @override
  String get timePeriodToday => 'Aujourd\'hui';

  @override
  String get timePeriodThisWeek => 'Cette semaine';

  @override
  String get timePeriodThisMonth => 'Ce mois';

  @override
  String get timePeriodCustom => 'Personnalisée';

  @override
  String get statsFor => 'Statistiques pour ';

  @override
  String get homescreenbrewcoffee => 'Faire du café';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Plus';

  @override
  String get addBeans => 'Ajouter des grains';

  @override
  String get removeBeans => 'Retirer des grains';

  @override
  String get name => 'Nom';

  @override
  String get origin => 'Origine';

  @override
  String get details => 'Détails';

  @override
  String get coffeebeans => 'Grains de café';

  @override
  String get loading => 'Chargement';

  @override
  String get nocoffeebeans => 'Aucun grain de café trouvé';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirmDeleteTitle => 'Supprimer l\'entrée ?';

  @override
  String get recipeDuplicateConfirmTitle => 'Dupliquer la recette ?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Ceci créera une copie de votre recette que vous pourrez modifier indépendamment. Voulez-vous continuer ?';

  @override
  String get confirmDeleteMessage =>
      'Êtes-vous sûr de vouloir supprimer cet élément ? Cette action est irréversible.';

  @override
  String get removeFavorite => 'Retirer des favoris';

  @override
  String get addFavorite => 'Ajouter aux favoris';

  @override
  String get toggleEditMode => 'Activer/désactiver le mode édition';

  @override
  String get coffeeBeansDetails => 'Détails des grains de café';

  @override
  String get edit => 'Modifier';

  @override
  String get coffeeBeansNotFound => 'Grains de café non trouvés';

  @override
  String get basicInformation => 'Informations de base';

  @override
  String get geographyTerroir => 'Géographie/Terroir';

  @override
  String get variety => 'Variété';

  @override
  String get region => 'Amérique du Nord';

  @override
  String get elevation => 'Altitude';

  @override
  String get harvestDate => 'Date de récolte';

  @override
  String get processing => 'Traitement';

  @override
  String get processingMethod => 'Méthode de traitement';

  @override
  String get roastDate => 'Date de torréfaction';

  @override
  String get roastLevel => 'Niveau de torréfaction';

  @override
  String get cuppingScore => 'Note de dégustation';

  @override
  String get flavorProfile => 'Profil aromatique';

  @override
  String get tastingNotes => 'Notes de dégustation';

  @override
  String get additionalNotes => 'Notes supplémentaires';

  @override
  String get noCoffeeBeans => 'Aucun grain de café trouvé';

  @override
  String get editCoffeeBeans => 'Modifier les grains de café';

  @override
  String get addCoffeeBeans => 'Ajouter des grains de café';

  @override
  String get showImagePicker => 'Afficher le sélecteur d\'images';

  @override
  String get pleaseNote => 'Veuillez noter';

  @override
  String get firstTimePopupMessage =>
      '1. Nous utilisons des services externes pour traiter les images. En continuant, vous acceptez cela.\n2. Bien que nous ne stockions pas vos images, veuillez éviter d\'inclure des informations personnelles.\n3. La reconnaissance d\'images est actuellement limitée à 10 jetons par mois (1 jeton = 1 image). Cette limite peut changer à l\'avenir.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get selectFromPhotos => 'Sélectionner dans les photos';

  @override
  String get takeAdditionalPhoto => 'Prendre une autre photo ?';

  @override
  String get no => 'Non';

  @override
  String get yes => 'Oui';

  @override
  String get selectedImages => 'Images sélectionnées';

  @override
  String get selectedImage => 'Image sélectionnée';

  @override
  String get backToSelection => 'Retour à la sélection';

  @override
  String get next => 'Suivant';

  @override
  String get unexpectedErrorOccurred => 'Une erreur inattendue s\'est produite';

  @override
  String get tokenLimitReached =>
      'Désolé, vous avez atteint votre limite de jetons pour la reconnaissance d\'images ce mois-ci';

  @override
  String get noCoffeeLabelsDetected =>
      'Aucune étiquette de café détectée. Essayez avec une autre image.';

  @override
  String get collectedInformation => 'Informations collectées';

  @override
  String get enterRoaster => 'Entrez le torréfacteur';

  @override
  String get enterName => 'Entrez le nom';

  @override
  String get enterOrigin => 'Entrez l\'origine';

  @override
  String get optional => 'Facultatif';

  @override
  String get enterVariety => 'Entrez la variété';

  @override
  String get enterProcessingMethod => 'Entrez la méthode de traitement';

  @override
  String get enterRoastLevel => 'Entrez le niveau de torréfaction';

  @override
  String get enterRegion => 'Entrez la région';

  @override
  String get enterTastingNotes => 'Entrez les notes de dégustation';

  @override
  String get enterElevation => 'Entrez l\'altitude';

  @override
  String get enterCuppingScore => 'Entrez la note de dégustation';

  @override
  String get enterNotes => 'Entrez les notes';

  @override
  String get inventory => 'Stock';

  @override
  String get amountLeft => 'Quantité restante';

  @override
  String get enterAmountLeft => 'Saisir la quantité restante';

  @override
  String get selectHarvestDate => 'Sélectionnez la date de récolte';

  @override
  String get selectRoastDate => 'Sélectionnez la date de torréfaction';

  @override
  String get selectDate => 'Sélectionnez la date';

  @override
  String get save => 'Enregistrer';

  @override
  String get fillRequiredFields =>
      'Veuillez remplir tous les champs obligatoires.';

  @override
  String get analyzing => 'Analyse en cours';

  @override
  String get errorMessage => 'Erreur';

  @override
  String get selectCoffeeBeans => 'Sélectionnez les grains de café';

  @override
  String get addNewBeans => 'Ajouter de nouveaux grains';

  @override
  String get favorite => 'Favori';

  @override
  String get notFavorite => 'Non favori';

  @override
  String get myBeans => 'Mes cafés';

  @override
  String get signIn => 'S’identifier';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get signInSuccessful => 'Connexion réussie avec Apple';

  @override
  String get signInError => 'Erreur lors de la connexion avec Apple';

  @override
  String get signInErrorGoogle => 'Erreur lors de la connexion avec Google';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get signOutSuccessful => 'Déconnexion réussie';

  @override
  String get signOutConfirmationTitle =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get signOutConfirmationMessage =>
      'La synchronisation cloud cessera de fonctionner. Reconnectez-vous pour la reprendre.';

  @override
  String get signInSuccessfulGoogle => 'Connexion à Google réussie';

  @override
  String get signInWithEmail => 'Se connecter avec un e-mail';

  @override
  String get enterEmail => 'Entrez votre e-mail';

  @override
  String get emailHint => 'exemple@e-mail.com';

  @override
  String get cancel => 'Annuler';

  @override
  String get sendMagicLink => 'Envoyer le lien magique';

  @override
  String get magicLinkSent => 'Lien magique envoyé ! Consultez votre e-mail.';

  @override
  String get sendOTP => 'Envoyer OTP';

  @override
  String get otpSent => 'OTP envoyé à votre email';

  @override
  String get otpSendError => 'Erreur lors de l\'envoi de l\'OTP';

  @override
  String get enterOTP => 'Entrez l\'OTP';

  @override
  String get otpHint => 'Entrez le code à 6 chiffres';

  @override
  String get verify => 'Vérifier';

  @override
  String get signInSuccessfulEmail => 'Connexion réussie';

  @override
  String get invalidOTP => 'OTP invalide';

  @override
  String get otpVerificationError => 'Erreur lors de la vérification de l\'OTP';

  @override
  String get success => 'Succès!';

  @override
  String get otpSentMessage =>
      'Un code OTP vous a été envoyé par e-mail. Veuillez le saisir ci-dessous lorsque vous l\'aurez reçu.';

  @override
  String get otpHint2 => 'Entrez le code ici';

  @override
  String get signInCreate => 'Se connecter / Créer un compte';

  @override
  String get accountManagement => 'Gestion du compte';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountWarning =>
      'Attention : si vous choisissez de continuer, nous supprimerons votre compte et les données associées de nos serveurs. La copie locale des données restera sur l’appareil. Si vous souhaitez également la supprimer, vous pouvez simplement supprimer l’application. Pour réactiver la synchronisation, vous devrez créer un nouveau compte.';

  @override
  String get deleteAccountConfirmation => 'Compte supprimé avec succès';

  @override
  String get accountDeleted => 'Compte supprimé';

  @override
  String get accountDeletionError =>
      'Erreur lors de la suppression de votre compte. Veuillez réessayer.';

  @override
  String get deleteAccountTitle => 'important';

  @override
  String get selectBeans => 'Sélectionner les grains';

  @override
  String get all => 'Tous';

  @override
  String get selectRoaster => 'Sélectionner un torréfacteur';

  @override
  String get selectOrigin => 'Sélectionner une origine';

  @override
  String get resetFilters => 'Réinitialiser les filtres';

  @override
  String get showFavoritesOnly => 'Afficher uniquement les favoris';

  @override
  String get apply => 'Appliquer';

  @override
  String get selectSize => 'Sélectionnez la taille';

  @override
  String get sizeStandard => 'Standard';

  @override
  String get sizeMedium => 'Moyen';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Mon année avec Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hé, merci d\'avoir fait partie de l\'univers Timer.Coffee cette année !';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Tout d\'abord.\nVous avez préparé du café cette année$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Pour être plus précis,\nvous avez infusé $liters litres de café en 2024 !';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Vous avez utilisé des grains de $roasterCount torréfacteurs';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Vos 3 meilleurs torréfacteurs étaient :\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Le café vous a fait voyager\nautour du monde$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Vous avez dégusté des grains de café\nde $originCount pays !';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Vous n\'étiez pas seul à infuser…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...mais avec des utilisateurs de 110 autres\npays sur 6 continents !';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Vous êtes resté fidèle à vous-même et n\'avez utilisé que ces $count méthodes d\'infusion cette année :';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Vous découvriez de nouvelles saveurs et avez utilisé $count méthodes d\'infusion cette année :';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Vous étiez un véritable découvreur de café et avez utilisé $count méthodes d\'infusion cette année :';
  }

  @override
  String get yearlyStatsStory9Text => 'Tant d\'autres choses à découvrir !';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Vos 3 meilleures recettes en 2024 étaient$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Rendez-vous en 2025 !';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Montrez un peu d\'amour ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Faire un don';

  @override
  String get yearlyStatsActionShare => 'Partager vos progrès';

  @override
  String get yearlyStatsUnknown => 'Inconnu';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Échec du partage : $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Mon année avec Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes =>
      'Mes 3 meilleures recettes :';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'Mes 3 meilleurs torréfacteurs :';

  @override
  String get yearlyStats25AppBarTitle => 'Votre année avec Timer.Coffee – 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee en 2025';

  @override
  String get yearlyStats25Slide1Title => 'Votre année avec Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'Touchez pour voir comment vous avez préparé du café en 2025';

  @override
  String get yearlyStats25Slide2Intro =>
      'Ensemble, nous avons préparé du café…';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count fois';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'Cela représente environ $liters litres de café';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'De quoi offrir une tasse de café à tout le monde à Cambridge, Royaume-Uni (les étudiants seraient particulièrement reconnaissants).';

  @override
  String get yearlyStats25Slide3Title => 'Et vous ?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'Cette année, vous avez préparé du café $brews fois avec Timer.Coffee. Soit $liters litres de café au total !';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'Vous êtes dans le top $topPct% des personnes qui préparent du café !';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'Vous souvenez-vous du jour où vous avez préparé le plus de café cette année ?';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'Vous souvenez-vous des jours où vous avez préparé le plus de café cette année ?';

  @override
  String get yearlyStats25Slide4TitleBrewTime =>
      'Votre temps de préparation cette année';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'Grattez pour révéler';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count infusions',
      one: '1 infusion',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'Environ $liters litres ce jour-là';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
      String mostRecent, String brewsLabel) {
    return 'Le plus récent : $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'Vous avez passé $timeLabel à préparer du café';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => 'Du temps bien investi';

  @override
  String get yearlyStats25Slide5Title =>
      'Voici comment vous préparez votre café';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'Méthodes favorites :';

  @override
  String get yearlyStats25Slide5NoMethods => 'Aucune méthode pour l’instant';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'Meilleures recettes :';

  @override
  String get yearlyStats25Slide5NoRecipes => 'Aucune recette pour l’instant';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'infusions',
      one: 'infusion',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'Vous avez découvert $count torréfacteurs cette année :';
  }

  @override
  String get yearlyStats25Slide6NoRoasters =>
      'Aucun torréfacteur pour l’instant';

  @override
  String get yearlyStats25Slide7Title =>
      'Boire du café peut vous emmener loin…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'Vous avez découvert $count origines cette année :';
  }

  @override
  String get yearlyStats25Others => '…et d’autres';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'Cette année, les utilisateurs de Timer.Coffee ont utilisé des grains de $countries pays\net enregistré $roasters torréfacteurs différents.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'Pourquoi ne pas continuer à enregistrer vos sacs de grains ?';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'Peut-être est-il temps de vous y mettre et d’enregistrer vos grains, vous aussi ?';

  @override
  String get yearlyStats25FallbackActionHasBeans =>
      'Continuer à ajouter des grains';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'Ajouter votre premier sac de grains';

  @override
  String get yearlyStats25ContinueButton => 'Continuer';

  @override
  String get yearlyStats25PostcardTitle =>
      'Envoyez un vœu de Nouvel An à un autre amateur de café.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'Optionnel. Restez bienveillant. Pas d’informations personnelles.';

  @override
  String get yearlyStats25PostcardHint => 'Bonne année et bonnes infusions !';

  @override
  String get yearlyStats25PostcardSending => 'Envoi...';

  @override
  String get yearlyStats25PostcardSend => 'Envoyer';

  @override
  String get yearlyStats25PostcardSkip => 'Passer';

  @override
  String get yearlyStats25PostcardReceivedTitle =>
      'Un vœu d’un autre amateur de café';

  @override
  String get yearlyStats25PostcardErrorLength =>
      'Veuillez saisir 2–160 caractères.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'Impossible d’envoyer. Veuillez réessayer.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'Impossible d’envoyer. Essayez un autre message.';

  @override
  String get yearlyStats25CtaTitle =>
      'Préparons quelque chose de génial en 2026 !';

  @override
  String get yearlyStats25CtaSubtitle => 'Voici quelques idées :';

  @override
  String get yearlyStats25CtaExplorePrefix => 'Découvrez les offres dans le ';

  @override
  String get yearlyStats25CtaGiftBox => 'Coffret Cadeaux de Fêtes';

  @override
  String get yearlyStats25CtaDonate => 'Faire un don';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' pour aider Timer.Coffee à grandir l’année à venir';

  @override
  String get yearlyStats25CtaFollowPrefix => 'Suivez-nous sur ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'Partager mes progrès';

  @override
  String get yearlyStats25CtaShareHint =>
      'N’oubliez pas de taguer @timercoffeeapp';

  @override
  String get yearlyStats25AppBarTooltipResume => 'Reprendre';

  @override
  String get yearlyStats25AppBarTooltipPause => 'Pause';

  @override
  String get yearlyStats25ShareError =>
      'Impossible de partager le récapitulatif. Veuillez réessayer.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours h';
  }

  @override
  String get yearlyStats25ShareTitle => 'Mon année 2025 avec Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'Infusions : ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' fois et ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' litres de café';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'Torréfacteurs : ';

  @override
  String get yearlyStats25ShareRoastersSuffix => '';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'Origines : ';

  @override
  String get yearlyStats25ShareOriginsSuffix => '';

  @override
  String get yearlyStats25ShareMethodsTitle =>
      'Mes méthodes de préparation préférées :';

  @override
  String get yearlyStats25ShareRecipesTitle => 'Mes meilleures recettes :';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

  @override
  String get yearlyStatsFailedToLike =>
      'Échec de l\'ajout aux favoris. Veuillez réessayer.';

  @override
  String get labelCoffeeBrewed => 'Cafés infusés';

  @override
  String get labelTastedBeansBy => 'Grains goûtés par';

  @override
  String get labelDiscoveredCoffeeFrom => 'Café découvert de';

  @override
  String get labelUsedBrewingMethods => 'Utilisé';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'torréfacteurs',
      one: 'torréfacteur',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pays',
      one: 'pays',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'méthodes d\'infusion',
      one: 'méthode d\'infusion',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Modifier la recette';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Créer une recette';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Étapes de la recette';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nom de la recette';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Description courte';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Méthode d\'infusion';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Quantité de café (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Quantité d\'eau (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Température de l\'eau (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Taille de mouture';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Temps total d\'infusion :';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minutes';

  @override
  String get recipeCreationScreenSecondsLabel => 'Secondes';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Étape de préparation';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Étape d\'infusion $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel =>
      'Description de l\'étape';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Temps de l\'étape : ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Veuillez entrer un nom de recette';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Veuillez entrer une description courte';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Veuillez sélectionner une méthode d\'infusion';

  @override
  String get recipeCreationScreenRequiredValidator => 'Requis';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Numéro invalide';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Veuillez entrer une description pour l\'étape';

  @override
  String get recipeCreationScreenContinueButton =>
      'Continuer vers les étapes de la recette';

  @override
  String get recipeCreationScreenAddStepButton => 'Ajouter une étape';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Enregistrer la recette';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Recette mise à jour avec succès';

  @override
  String get recipeCreationScreenSaveSuccess =>
      'Recette enregistrée avec succès';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Erreur lors de l\'enregistrement de la recette : $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'grammes';

  @override
  String get unitMillilitersLong => 'millilitres';

  @override
  String get recipeCopySuccess => 'Recette copiée avec succès !';

  @override
  String get recipeDuplicateSuccess => 'Recette dupliquée avec succès !';

  @override
  String recipeCopyError(String error) {
    return 'Erreur lors de la copie de la recette : $error';
  }

  @override
  String get createRecipe => 'Créer une recette';

  @override
  String errorSyncingData(Object error) {
    return 'Erreur de synchronisation des données : $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Erreur de déconnexion : $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Préparation';

  @override
  String get loadingEllipsis => 'Chargement...';

  @override
  String get recipeDeletedSuccess => 'Recette supprimée avec succès';

  @override
  String recipeDeleteError(Object error) {
    return 'Erreur lors de la suppression de la recette : $error';
  }

  @override
  String get noRecipesFound => 'Aucune recette trouvée';

  @override
  String recipeLoadError(Object error) {
    return 'Erreur lors du chargement de la recette : $error';
  }

  @override
  String get unknownBrewingMethod => 'Méthode d\'infusion inconnue';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Erreur lors du chargement de la recette copiée pour modification.';

  @override
  String get recipeCopyErrorOperationFailed => 'L\'opération a échoué.';

  @override
  String get notProvided => 'Non fourni';

  @override
  String get recipeUpdateFailedFetch =>
      'Échec de la récupération des données de recette mises à jour.';

  @override
  String get recipeImportSuccess => 'Recette importée avec succès !';

  @override
  String get recipeImportFailedSave =>
      'Échec de l\'enregistrement de la recette importée.';

  @override
  String get recipeImportFailedFetch =>
      'Échec de la récupération des données de recette pour l\'importation.';

  @override
  String get recipeNotImported => 'Recette non importée.';

  @override
  String get recipeNotFoundCloud =>
      'Recette introuvable dans le cloud ou non publique.';

  @override
  String get recipeLoadErrorGeneric =>
      'Erreur lors du chargement de la recette.';

  @override
  String get recipeUpdateAvailableTitle => 'Mise à jour disponible';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Une version plus récente de \'$recipeName\' est disponible en ligne. Mettre à jour ?';
  }

  @override
  String get dialogCancel => 'Annuler';

  @override
  String get dialogDuplicate => 'Dupliquer';

  @override
  String get dialogUpdate => 'Mettre à jour';

  @override
  String get recipeImportTitle => 'Importer la recette';

  @override
  String recipeImportBody(String recipeName) {
    return 'Voulez-vous importer la recette \'$recipeName\' depuis le cloud ?';
  }

  @override
  String get dialogImport => 'Importer';

  @override
  String get moderationReviewNeededTitle => 'Examen de modération requis';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'La ou les recettes suivantes nécessitent un examen en raison de problèmes de modération de contenu : $recipeNames';
  }

  @override
  String get dismiss => 'Ignorer';

  @override
  String get reviewRecipeButton => 'Examiner la recette';

  @override
  String get signInRequiredTitle => 'Connexion requise';

  @override
  String get signInRequiredBodyShare =>
      'Vous devez vous connecter pour partager vos propres recettes.';

  @override
  String get syncSuccess => 'Synchronisation réussie !';

  @override
  String get tooltipEditRecipe => 'Modifier la recette';

  @override
  String get tooltipCopyRecipe => 'Copier la recette';

  @override
  String get tooltipDuplicateRecipe => 'Dupliquer la recette';

  @override
  String get tooltipShareRecipe => 'Partager la recette';

  @override
  String get signInRequiredSnackbar => 'Connexion requise';

  @override
  String get moderationErrorFunction =>
      'La vérification de la modération du contenu a échoué.';

  @override
  String get moderationReasonDefault => 'Contenu signalé pour examen.';

  @override
  String get moderationFailedTitle => 'Échec de la modération';

  @override
  String moderationFailedBody(String reason) {
    return 'Cette recette ne peut pas être partagée car : $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Erreur lors du partage de la recette : $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName sur Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Impossible de vérifier l\'état du contenu. Enregistré localement, sera vérifié lors de la prochaine synchronisation.';

  @override
  String get saveLocallyModerationFailedTitle =>
      'Modifications enregistrées localement';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Vos modifications locales ont été enregistrées, mais la version publique n\'a pas pu être mise à jour en raison de la modération du contenu : $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Modifier la recette importée';

  @override
  String get editImportedRecipeBody =>
      'Ceci est une recette importée. La modifier créera une nouvelle copie indépendante. Voulez-vous continuer ?';

  @override
  String get editImportedRecipeButtonCopy => 'Créer une copie et modifier';

  @override
  String get editImportedRecipeButtonCancel => 'Annuler';

  @override
  String get editDisplayNameTitle => 'Modifier le nom d\'affichage';

  @override
  String get displayNameHint => 'Entrez votre nom d\'affichage';

  @override
  String get displayNameEmptyError =>
      'Le nom d\'affichage ne peut pas être vide';

  @override
  String get displayNameTooLongError =>
      'Le nom d\'affichage ne peut pas dépasser 50 caractères';

  @override
  String get errorUserNotLoggedIn =>
      'Utilisateur non connecté. Veuillez vous reconnecter.';

  @override
  String get displayNameUpdateSuccess =>
      'Nom d\'affichage mis à jour avec succès !';

  @override
  String displayNameUpdateError(String error) {
    return 'Échec de la mise à jour du nom d\'affichage : $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Supprimer l\'image ?';

  @override
  String get deletePictureConfirmationBody =>
      'Êtes-vous sûr de vouloir supprimer votre photo de profil ?';

  @override
  String get deletePictureSuccess => 'Photo de profil supprimée.';

  @override
  String deletePictureError(String error) {
    return 'Échec de la suppression de la photo de profil : $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Échec de la mise à jour de la photo de profil : $error';
  }

  @override
  String get updatePictureSuccess =>
      'Photo de profil mise à jour avec succès !';

  @override
  String get deletePictureTooltip => 'Supprimer l\'image';

  @override
  String get account => 'Compte';

  @override
  String get settingsBrewingMethodsTitle =>
      'Méthodes d\'infusion sur l\'écran d\'accueil';

  @override
  String get filter => 'Filtrer';

  @override
  String get sortBy => 'Trier par';

  @override
  String get dateAdded => 'Date d\'ajout';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Icône de l\'application';

  @override
  String get settingsAppIconDefault => 'Défaut';

  @override
  String get settingsAppIconLegacy => 'Ancien';

  @override
  String get searchBeans => 'Rechercher des grains...';

  @override
  String get favorites => 'Favoris';

  @override
  String get searchPrefix => 'Recherche : ';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get noBeansMatchSearch =>
      'Aucun grain ne correspond à votre recherche';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get farmer => 'Agriculteur';

  @override
  String get farm => 'Plantation de café';

  @override
  String get enterFarmer => 'Entrez l\'agriculteur';

  @override
  String get enterFarm => 'Entrez la plantation de café';

  @override
  String get requiredInformation => 'Informations requises';

  @override
  String get basicDetails => 'Détails de base';

  @override
  String get qualityMeasurements => 'Qualité et mesures';

  @override
  String get importantDates => 'Dates importantes';

  @override
  String get brewStats => 'Statistiques de préparation';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get unpublishRecipeDialogTitle => 'Rendre la recette privée';

  @override
  String get unpublishRecipeDialogMessage =>
      'Avertissement : Rendre cette recette privée va :';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'La supprimer des résultats de recherche publics';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Empêcher les nouveaux utilisateurs de l\'importer';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Les utilisateurs qui l\'ont déjà importée conserveront leurs copies';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Garder publique';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Rendre privée';

  @override
  String get recipeUnpublishSuccess => 'Recette dépubliée avec succès';

  @override
  String recipeUnpublishError(String error) {
    return 'Échec de la dépublication de la recette : $error';
  }

  @override
  String get recipePublicTooltip =>
      'La recette est publique - appuyez pour la rendre privée';

  @override
  String get recipePrivateTooltip =>
      'La recette est privée - partagez pour la rendre publique';

  @override
  String get fieldClearButtonTooltip => 'Effacer';

  @override
  String get dateFieldClearButtonTooltip => 'Effacer la date';

  @override
  String get chipInputDuplicateError => 'Cette étiquette a déjà été ajoutée';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Nombre maximum d\'étiquettes atteint ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Ajouter une étiquette...';

  @override
  String get unitFieldRequiredError => 'Ce champ est obligatoire';

  @override
  String get unitFieldInvalidNumberError => 'Veuillez entrer un nombre valide';

  @override
  String unitFieldMinValueError(Object min) {
    return 'La valeur doit être au moins $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'La valeur doit être au plus $max';
  }

  @override
  String get numericFieldRequiredError => 'Ce champ est obligatoire';

  @override
  String get numericFieldInvalidNumberError =>
      'Veuillez entrer un nombre valide';

  @override
  String numericFieldMinValueError(Object min) {
    return 'La valeur doit être au moins $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'La valeur doit être au plus $max';
  }

  @override
  String get dropdownSearchHintText => 'Tapez pour rechercher...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Erreur lors du chargement des suggestions : $error';
  }

  @override
  String get dropdownSearchNoResults => 'Aucun résultat trouvé';

  @override
  String get dropdownSearchLoading => 'Recherche...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Utiliser \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Obligatoire';

  @override
  String get inventoryWeightExample => 'ex. 250,5';

  @override
  String get unsavedChangesTitle => 'Modifications non enregistrées';

  @override
  String get unsavedChangesMessage =>
      'Vous avez des modifications non enregistrées. Êtes-vous sûr de vouloir les abandonner ?';

  @override
  String get unsavedChangesStay => 'Rester';

  @override
  String get unsavedChangesDiscard => 'Abandonner';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return '$amount$unit ajoutés à $beanName. Nouveau poids : $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return '$amount$unit soustraits de $beanName. Nouveau poids : $newWeight$unit';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Désactivé dans les paramètres système';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get notificationsDisabledDialogTitle =>
      'Notifications désactivées dans les paramètres système';

  @override
  String get notificationsDisabledDialogContent =>
      'Vous avez désactivé les notifications dans les paramètres de votre appareil. Pour activer les notifications, veuillez ouvrir les paramètres de votre appareil et autoriser les notifications pour Timer.Coffee.';

  @override
  String get notificationDebug => 'Débogage des notifications';

  @override
  String get testNotificationSystem => 'Tester le système de notifications';

  @override
  String get notificationsEnabled => 'Activé';

  @override
  String get notificationsDisabled => 'Désactivé';

  @override
  String get notificationPermissionDialogTitle => 'Activer les notifications ?';

  @override
  String get notificationPermissionDialogMessage =>
      'Vous pouvez activer les notifications pour recevoir des mises à jour utiles (par ex. sur les nouvelles versions de l\'application). Activez maintenant ou modifiez ce paramètre à tout moment dans les réglages.';

  @override
  String get notificationPermissionEnable => 'Activer';

  @override
  String get notificationPermissionSkip => 'Pas maintenant';

  @override
  String get holidayGiftBoxTitle => 'Coffret Cadeaux de Fêtes';

  @override
  String get holidayGiftBoxInfoTrigger => 'Qu’est-ce que c’est ?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Offres saisonnières sélectionnées chez nos partenaires. Liens non affiliés - notre but est simplement d\'apporter un peu de joie aux utilisateurs de Timer.Coffee pendant ces fêtes. Tirez pour actualiser à tout moment.';

  @override
  String get holidayGiftBoxNoOffers =>
      'Aucune offre disponible pour le moment.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Tirez pour actualiser ou réessayez plus tard.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Offres pour $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Voir les détails';

  @override
  String get holidayGiftBoxPromoCopied => 'Code promo copié';

  @override
  String get holidayGiftBoxPromoCode => 'Code promo';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% de réduction';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Jusqu’à $percent% de réduction';
  }

  @override
  String get holidayGiftBoxTerms => 'Conditions générales';

  @override
  String get holidayGiftBoxVisitSite => 'Visiter le site du partenaire';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Valable jusqu’au $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Se termine dans $days jours',
      one: 'Se termine demain',
      zero: 'Se termine aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable =>
      'Valable dans la limite des stocks';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Mis à jour le $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Langue : $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Réessayer';

  @override
  String get holidayGiftBoxLoadFailed => 'Échec du chargement des offres';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Offre indisponible';

  @override
  String get holidayGiftBoxBannerTitle =>
      'Découvrez notre coffret cadeau de fêtes';

  @override
  String get holidayGiftBoxBannerCta => 'Voir les offres';

  @override
  String get regionEurope => 'Europe';

  @override
  String get regionNorthAmerica => 'Amérique du Nord';

  @override
  String get regionAsia => 'Asie';

  @override
  String get regionAustralia => 'Australie / Océanie';

  @override
  String get regionWorldwide => 'Monde entier';

  @override
  String get regionAfrica => 'Afrique';

  @override
  String get regionMiddleEast => 'Moyen-Orient';

  @override
  String get regionSouthAmerica => 'Amérique du Sud';

  @override
  String get setToZeroButton => 'Mettre à zéro';

  @override
  String get setToZeroDialogTitle => 'Mettre le stock à zéro ?';

  @override
  String get setToZeroDialogBody =>
      'Cela définira la quantité restante à 0 g. Vous pourrez la modifier plus tard.';

  @override
  String get setToZeroDialogConfirm => 'Mettre à zéro';

  @override
  String get setToZeroDialogCancel => 'Annuler';

  @override
  String get inventorySetToZeroSuccess => 'Stock défini à 0 g';

  @override
  String get inventorySetToZeroFail => 'Impossible de mettre le stock à zéro';
}
