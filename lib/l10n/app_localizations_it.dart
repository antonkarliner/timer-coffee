// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get lastrecipe => 'Ricetta Utilizzata Più di Recente:';

  @override
  String get about => 'Informazioni';

  @override
  String get author => 'Autore';

  @override
  String get authortext =>
      'L\'app Timer.Coffee è stata creata da Anton Karliner, un appassionato di caffè, specialista dei media e fotogiornalista. Spero che questa app ti aiuti a goderti il tuo caffè. Sentiti libero di contribuire su GitHub.';

  @override
  String get contributors => 'Collaboratori';

  @override
  String get errorLoadingContributors =>
      'Errore nel caricamento dei Collaboratori';

  @override
  String get license => 'Licenza';

  @override
  String get licensetext =>
      'Questa applicazione è un software libero: puoi ridistribuirlo e/o modificarlo sotto i termini della GNU General Public License come pubblicata dalla Free Software Foundation, sia la versione 3 della Licenza, o (a tua scelta) qualsiasi versione successiva.';

  @override
  String get licensebutton => 'Leggi la GNU General Public License v3';

  @override
  String get website => 'Sito Web';

  @override
  String get sourcecode => 'Codice Sorgente';

  @override
  String get support => 'Offrimi un caffè';

  @override
  String get allrecipes => 'Tutte le Ricette';

  @override
  String get favoriterecipes => 'Ricette Preferite';

  @override
  String get coffeeamount => 'Quantità di caffè (g)';

  @override
  String get wateramount => 'Quantità di acqua (ml)';

  @override
  String get watertemp => 'Temperatura dell\'Acqua';

  @override
  String get grindsize => 'Grandezza della Macinatura';

  @override
  String get brewtime => 'Tempo di Infusione';

  @override
  String get recipesummary => 'Sommario della Ricetta';

  @override
  String get recipesummarynote =>
      'Nota: questa è una ricetta base con quantità di acqua e caffè predefinite.';

  @override
  String get preparation => 'Preparazione';

  @override
  String get brewingprocess => 'Processo di Infusione';

  @override
  String get step => 'Passaggio';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'secondi',
      one: 'secondo',
      zero: 'secondi',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Grazie per aver utilizzato Timer.Coffee! Goditi il tuo';

  @override
  String get coffeefact => 'Curiosità sul Caffè';

  @override
  String get home => 'Home';

  @override
  String get appversion => 'Versione dell\'App';

  @override
  String get tipsmall => 'Offri un caffè piccolo';

  @override
  String get tipmedium => 'Offri un caffè medio';

  @override
  String get tiplarge => 'Offri un caffè grande';

  @override
  String get supportdevelopment => 'Supporta lo sviluppo';

  @override
  String get supportdevmsg =>
      'Le tue donazioni aiutano a coprire i costi di manutenzione (come le licenze per sviluppatori, ad esempio). Mi permettono anche di provare più dispositivi per la preparazione del caffè e aggiungere più ricette all\'app.';

  @override
  String get supportdevtnx => 'Grazie per aver considerato di donare!';

  @override
  String get donationok => 'Grazie!';

  @override
  String get donationtnx =>
      'Apprezzo davvero il tuo supporto! Ti auguro tante ottime infusioni! ☕️';

  @override
  String get donationerr => 'Errore';

  @override
  String get donationerrmsg =>
      'Errore nell\'elaborazione dell\'acquisto, per favore prova di nuovo.';

  @override
  String get sharemsg => 'Dai un\'occhiata a questa ricetta:';

  @override
  String get finishbrew => 'Termina';

  @override
  String get settings => 'Impostazioni';

  @override
  String get settingstheme => 'Tema';

  @override
  String get settingsthemelight => 'Chiaro';

  @override
  String get settingsthemedark => 'Scuro';

  @override
  String get settingsthemesystem => 'Sistema';

  @override
  String get settingslang => 'Lingua';

  @override
  String get sweet => 'Dolce';

  @override
  String get balance => 'Bilanciato';

  @override
  String get acidic => 'Acidulo';

  @override
  String get light => 'Leggero';

  @override
  String get strong => 'Forte';

  @override
  String get slidertitle => 'Usa i cursori per regolare il gusto';

  @override
  String get whatsnewtitle => 'Novità';

  @override
  String get whatsnewclose => 'Chiudi';

  @override
  String get seasonspecials => 'Specialità Stagionali';

  @override
  String get snow => 'Neve';

  @override
  String get noFavoriteRecipesMessage =>
      'La tua lista di ricette preferite è attualmente vuota. Inizia ad esplorare e preparare per scoprire i tuoi preferiti!';

  @override
  String get explore => 'Esplorare';

  @override
  String get dateFormat => 'd MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Diario di Infusione';

  @override
  String get brewdiarynotfound => 'Nessuna voce trovata';

  @override
  String get beans => 'Chicchi';

  @override
  String get roaster => 'Tostatore';

  @override
  String get rating => 'Valutazione';

  @override
  String get notes => 'Note';

  @override
  String get statsscreen => 'Statistica caffè';

  @override
  String get yourStats => 'Le tue statistiche';

  @override
  String get coffeeBrewed => 'Caffè preparato:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Ricette più utilizzate:';

  @override
  String get globalStats => 'Statistiche globali';

  @override
  String get unknownRecipe => 'Ricetta sconosciuta';

  @override
  String get noData => 'Nessun dato';

  @override
  String error(Object error) {
    return 'Errore: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Qualcuno ha appena preparato $recipeName';
  }

  @override
  String get timePeriodToday => 'Oggi';

  @override
  String get timePeriodThisWeek => 'Questa settimana';

  @override
  String get timePeriodThisMonth => 'Questo mese';

  @override
  String get timePeriodCustom => 'Personalizza';

  @override
  String get statsFor => 'Statistiche per ';

  @override
  String get homescreenbrewcoffee => 'Prepara caffè';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Altro';

  @override
  String get addBeans => 'Aggiungi chicchi';

  @override
  String get removeBeans => 'Rimuovi chicchi';

  @override
  String get name => 'Nome';

  @override
  String get origin => 'Origine';

  @override
  String get details => 'Dettagli';

  @override
  String get coffeebeans => 'Chicchi di caffè';

  @override
  String get loading => 'Caricamento in corso';

  @override
  String get nocoffeebeans => 'Nessun chicco di caffè trovato';

  @override
  String get delete => 'Elimina';

  @override
  String get confirmDeleteTitle => 'Eliminare la voce?';

  @override
  String get confirmDeleteMessage =>
      'Sei sicuro di voler eliminare questa voce? Questa azione non può essere annullata.';

  @override
  String get removeFavorite => 'Rimuovi dai preferiti';

  @override
  String get addFavorite => 'Aggiungi ai preferiti';

  @override
  String get toggleEditMode => 'Attiva/disattiva modalità di modifica';

  @override
  String get coffeeBeansDetails => 'Dettagli sui chicchi di caffè';

  @override
  String get edit => 'Modifica';

  @override
  String get coffeeBeansNotFound => 'Chicchi di caffè non trovati';

  @override
  String get geographyTerroir => 'Geografia/Terroir';

  @override
  String get variety => 'Varietà';

  @override
  String get region => 'Regione';

  @override
  String get elevation => 'Altitudine';

  @override
  String get harvestDate => 'Data di raccolta';

  @override
  String get processing => 'Lavorazione';

  @override
  String get processingMethod => 'Metodo di lavorazione';

  @override
  String get roastDate => 'Data di tostatura';

  @override
  String get roastLevel => 'Livello di tostatura';

  @override
  String get cuppingScore => 'Punteggio di degustazione';

  @override
  String get flavorProfile => 'Profilo aromatico';

  @override
  String get tastingNotes => 'Note di degustazione';

  @override
  String get additionalNotes => 'Note aggiuntive';

  @override
  String get noCoffeeBeans => 'Nessun chicco di caffè trovato';

  @override
  String get editCoffeeBeans => 'Modifica chicchi di caffè';

  @override
  String get addCoffeeBeans => 'Aggiungi chicchi di caffè';

  @override
  String get showImagePicker => 'Mostra selettore immagini';

  @override
  String get pleaseNote => 'Nota bene';

  @override
  String get firstTimePopupMessage =>
      '1. Utilizziamo servizi esterni per elaborare le immagini. Continuando, accetti questa condizione.\n2. Sebbene non memorizziamo le tue immagini, evita di includere dati personali.\n3. Il riconoscimento delle immagini è attualmente limitato a 10 token al mese (1 token = 1 immagine). Questo limite potrebbe cambiare in futuro.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Scatta una foto';

  @override
  String get selectFromPhotos => 'Seleziona dalle foto';

  @override
  String get takeAdditionalPhoto => 'Scattare un\'altra foto?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Sì';

  @override
  String get selectedImages => 'Immagini selezionate';

  @override
  String get selectedImage => 'Immagine selezionata';

  @override
  String get backToSelection => 'Torna alla selezione';

  @override
  String get next => 'Avanti';

  @override
  String get unexpectedErrorOccurred => 'Si è verificato un errore imprevisto';

  @override
  String get tokenLimitReached =>
      'Siamo spiacenti, hai raggiunto il limite di token per il riconoscimento delle immagini di questo mese';

  @override
  String get noCoffeeLabelsDetected =>
      'Nessuna etichetta di caffè rilevata. Riprova con un\'altra immagine.';

  @override
  String get collectedInformation => 'Informazioni raccolte';

  @override
  String get enterRoaster => 'Inserisci il torrefattore';

  @override
  String get enterName => 'Inserisci il nome';

  @override
  String get enterOrigin => 'Inserisci l\'origine';

  @override
  String get optional => 'Facoltativo';

  @override
  String get enterVariety => 'Inserisci la varietà';

  @override
  String get enterProcessingMethod => 'Inserisci il metodo di lavorazione';

  @override
  String get enterRoastLevel => 'Inserisci il livello di tostatura';

  @override
  String get enterRegion => 'Inserisci la regione';

  @override
  String get enterTastingNotes => 'Inserisci le note di degustazione';

  @override
  String get enterElevation => 'Inserisci l\'altitudine';

  @override
  String get enterCuppingScore => 'Inserisci il punteggio di degustazione';

  @override
  String get enterNotes => 'Inserisci le note';

  @override
  String get selectHarvestDate => 'Seleziona la data di raccolta';

  @override
  String get selectRoastDate => 'Seleziona la data di tostatura';

  @override
  String get selectDate => 'Seleziona la data';

  @override
  String get save => 'Salva';

  @override
  String get fillRequiredFields => 'Compila tutti i campi obbligatori.';

  @override
  String get analyzing => 'Analisi in corso';

  @override
  String get errorMessage => 'Errore';

  @override
  String get selectCoffeeBeans => 'Seleziona i chicchi di caffè';

  @override
  String get addNewBeans => 'Aggiungi nuovi chicchi';

  @override
  String get favorite => 'Preferito';

  @override
  String get notFavorite => 'Non preferito';

  @override
  String get myBeans => 'I miei chicchi';

  @override
  String get signIn => 'Accedi';

  @override
  String get signOut => 'Esci';

  @override
  String get signInWithApple => 'Accedi con Apple';

  @override
  String get signInSuccessful => 'Accesso con Apple completato correttamente';

  @override
  String get signInError => 'Errore durante l\'accesso con Apple';

  @override
  String get signInWithGoogle => 'Accedi con Google';

  @override
  String get signOutSuccessful => 'Disconnessione eseguita correttamente';

  @override
  String get signInSuccessfulGoogle =>
      'Accesso effettuato correttamente con Google';

  @override
  String get signInWithEmail => 'Accedi con Email';

  @override
  String get enterEmail => 'Inserisci la tua email';

  @override
  String get emailHint => 'esempio@email.com';

  @override
  String get cancel => 'Annulla';

  @override
  String get sendMagicLink => 'Invia Magic Link';

  @override
  String get magicLinkSent =>
      'Magic link inviato! Controlla la tua casella di posta.';

  @override
  String get sendOTP => 'Invia OTP';

  @override
  String get otpSent => 'OTP inviato all\'indirizzo email specificato';

  @override
  String get otpSendError => 'Errore durante l\'invio dell\'OTP';

  @override
  String get enterOTP => 'Inserisci OTP';

  @override
  String get otpHint => 'Inserisci il codice a 6 cifre';

  @override
  String get verify => 'Verifica';

  @override
  String get signInSuccessfulEmail => 'Accesso effettuato';

  @override
  String get invalidOTP => 'OTP non valido';

  @override
  String get otpVerificationError => 'Errore durante la verifica dell\'OTP';

  @override
  String get success => 'Operazione riuscita!';

  @override
  String get otpSentMessage =>
      'Un codice monouso (OTP) è stato inviato alla tua email. Inseriscilo di seguito quando lo ricevi.';

  @override
  String get otpHint2 => 'Inserisci il codice qui';

  @override
  String get signInCreate => 'Accedi / Crea account';

  @override
  String get accountManagement => 'Gestione account';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountWarning =>
      'Attenzione: se decidi di continuare, elimineremo il tuo account e i dati ad esso associati dai nostri server. La copia locale dei dati rimarrà sul dispositivo. Se desideri eliminarla, puoi semplicemente disinstallare l\'app. Per riattivare la sincronizzazione, dovrai creare nuovamente un account.';

  @override
  String get deleteAccountConfirmation => 'Account eliminato correttamente';

  @override
  String get accountDeleted => 'Account eliminato';

  @override
  String get accountDeletionError =>
      'Errore durante l\'eliminazione dell\'account. Riprova.';

  @override
  String get deleteAccountTitle => 'Importante';

  @override
  String get selectBeans => 'Seleziona chicchi';

  @override
  String get all => 'Tutti';

  @override
  String get selectRoaster => 'Seleziona torrefazione';

  @override
  String get selectOrigin => 'Seleziona origine';

  @override
  String get resetFilters => 'Reimposta filtri';

  @override
  String get showFavoritesOnly => 'Mostra solo i preferiti';

  @override
  String get apply => 'Applica';

  @override
  String get selectSize => 'Seleziona dimensione';

  @override
  String get sizeStandard => 'Standard';

  @override
  String get sizeMedium => 'Medio';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Il mio anno con Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Ehi, grazie per essere stato parte dell\'universo di Timer.Coffee quest\'anno!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Per prima cosa.\nQuest\'anno hai preparato un po\' di caffè$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Per essere più precisi,\nhai preparato $liters litri di caffè nel 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Hai usato chicchi di $roasterCount torrefazioni';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Le tue 3 torrefazioni migliori sono state:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Il caffè ti ha portato in viaggio\nper il mondo$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Hai assaggiato chicchi di caffè\ndi $originCount paesi!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Non stavi preparando da solo...';

  @override
  String get yearlyStatsStory7Part2 =>
      '...ma con utenti di altri 110\npaesi in 6 continenti!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Sei rimasto fedele a te stesso e quest\'anno hai utilizzato solo questi $count metodi di preparazione:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Stavi scoprendo nuovi gusti e quest\'anno hai utilizzato $count metodi di preparazione:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Eri un vero scopritore di caffè e quest\'anno hai utilizzato $count metodi di preparazione:';
  }

  @override
  String get yearlyStatsStory9Text => 'Tanto altro da scoprire!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Le tue 3 migliori ricette nel 2024 sono state$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Ci vediamo nel 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Mostra un po\' di amore ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Dona';

  @override
  String get yearlyStatsActionShare => 'Condividi i tuoi progressi';

  @override
  String get yearlyStatsUnknown => 'Sconosciuto';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Impossibile condividere: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Il mio anno con Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes =>
      'Le mie 3 ricette migliori:';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'I miei 3 torrefattori migliori:';

  @override
  String get yearlyStatsFailedToLike =>
      'Impossibile mettere mi piace. Riprova.';

  @override
  String get labelCoffeeBrewed => 'Caffè preparato';

  @override
  String get labelTastedBeansBy => 'Chicchi assaggiati da';

  @override
  String get labelDiscoveredCoffeeFrom => 'Caffè scoperto da';

  @override
  String get labelUsedBrewingMethods => 'Utilizzati';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'torrefattori',
      one: 'torrefattore',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paesi',
      one: 'paese',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'metodi di infusione',
      one: 'metodo di infusione',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Modifica Ricetta';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Crea Ricetta';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Passaggi della Ricetta';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nome Ricetta';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Descrizione Breve';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Metodo di Infusione';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Quantità Caffè (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Quantità Acqua (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Temperatura Acqua (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Dimensione Macinatura';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Tempo Totale Infusione:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minuti';

  @override
  String get recipeCreationScreenSecondsLabel => 'Secondi';

  @override
  String get recipeCreationScreenPreparationStepTitle =>
      'Passaggio di Preparazione';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Passaggio di Infusione $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel =>
      'Descrizione Passaggio';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Tempo Passaggio: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Inserisci un nome per la ricetta';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Inserisci una descrizione breve';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Seleziona un metodo di infusione';

  @override
  String get recipeCreationScreenRequiredValidator => 'Obbligatorio';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Numero non valido';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Inserisci una descrizione per il passaggio';

  @override
  String get recipeCreationScreenContinueButton =>
      'Continua ai Passaggi della Ricetta';

  @override
  String get recipeCreationScreenAddStepButton => 'Aggiungi Passaggio';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Salva Ricetta';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Ricetta aggiornata con successo';

  @override
  String get recipeCreationScreenSaveSuccess => 'Ricetta salvata con successo';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Errore nel salvataggio della ricetta: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'grammi';

  @override
  String get unitMillilitersLong => 'millilitri';

  @override
  String get recipeCopySuccess => 'Ricetta copiata con successo!';

  @override
  String recipeCopyError(String error) {
    return 'Errore durante la copia della ricetta: $error';
  }

  @override
  String get createRecipe => 'Crea ricetta';

  @override
  String errorSyncingData(Object error) {
    return 'Errore di sincronizzazione dati: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Errore di disconnessione: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Preparazione';

  @override
  String get loadingEllipsis => 'Caricamento...';

  @override
  String get recipeDeletedSuccess => 'Ricetta eliminata con successo';

  @override
  String recipeDeleteError(Object error) {
    return 'Errore nell\'eliminazione della ricetta: $error';
  }

  @override
  String get noRecipesFound => 'Nessuna ricetta trovata';

  @override
  String recipeLoadError(Object error) {
    return 'Errore nel caricamento della ricetta: $error';
  }

  @override
  String get unknownBrewingMethod => 'Metodo di estrazione sconosciuto';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Errore nel caricamento della ricetta copiata per la modifica.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operazione fallita.';

  @override
  String get notProvided => 'Non fornito';

  @override
  String get recipeUpdateFailedFetch =>
      'Impossibile recuperare i dati aggiornati della ricetta.';

  @override
  String get recipeImportSuccess => 'Ricetta importata con successo!';

  @override
  String get recipeImportFailedSave =>
      'Impossibile salvare la ricetta importata.';

  @override
  String get recipeImportFailedFetch =>
      'Impossibile recuperare i dati della ricetta per l\'importazione.';

  @override
  String get recipeNotImported => 'Ricetta non importata.';

  @override
  String get recipeNotFoundCloud =>
      'Ricetta non trovata nel cloud o non pubblica.';

  @override
  String get recipeLoadErrorGeneric => 'Errore nel caricamento della ricetta.';

  @override
  String get recipeUpdateAvailableTitle => 'Aggiornamento disponibile';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'È disponibile una versione più recente di \'$recipeName\' online. Aggiornare?';
  }

  @override
  String get dialogCancel => 'Annulla';

  @override
  String get dialogUpdate => 'Aggiorna';

  @override
  String get recipeImportTitle => 'Importa ricetta';

  @override
  String recipeImportBody(String recipeName) {
    return 'Vuoi importare la ricetta \'$recipeName\' dal cloud?';
  }

  @override
  String get dialogImport => 'Importa';

  @override
  String get moderationReviewNeededTitle =>
      'Revisione della moderazione necessaria';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'La/e seguente/i ricetta/e richiede/ono una revisione a causa di problemi di moderazione dei contenuti: $recipeNames';
  }

  @override
  String get dismiss => 'Ignora';

  @override
  String get reviewRecipeButton => 'Rivedi Ricetta';

  @override
  String get signInRequiredTitle => 'Accesso richiesto';

  @override
  String get signInRequiredBodyShare =>
      'Devi accedere per condividere le tue ricette.';

  @override
  String get syncSuccess => 'Sincronizzazione riuscita!';

  @override
  String get tooltipEditRecipe => 'Modifica Ricetta';

  @override
  String get tooltipCopyRecipe => 'Copia Ricetta';

  @override
  String get tooltipShareRecipe => 'Condividi Ricetta';

  @override
  String get signInRequiredSnackbar => 'Accesso richiesto';

  @override
  String get moderationErrorFunction =>
      'Controllo della moderazione dei contenuti fallito.';

  @override
  String get moderationReasonDefault => 'Contenuto segnalato per la revisione.';

  @override
  String get moderationFailedTitle => 'Moderazione Fallita';

  @override
  String moderationFailedBody(String reason) {
    return 'Questa ricetta non può essere condivisa perché: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Errore nella condivisione della ricetta: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName su Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Impossibile controllare lo stato del contenuto. Salvato localmente, verrà controllato alla prossima sincronizzazione.';

  @override
  String get saveLocallyModerationFailedTitle => 'Modifiche Salvate Localmente';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Le tue modifiche locali sono state salvate, ma la versione pubblica non è stata aggiornata a causa della moderazione dei contenuti: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Modifica ricetta importata';

  @override
  String get editImportedRecipeBody =>
      'Questa è una ricetta importata. Modificandola verrà creata una nuova copia indipendente. Vuoi continuare?';

  @override
  String get editImportedRecipeButtonCopy => 'Crea copia e modifica';

  @override
  String get editImportedRecipeButtonCancel => 'Annulla';

  @override
  String get editDisplayNameTitle => 'Modifica nome visualizzato';

  @override
  String get displayNameHint => 'Inserisci il tuo nome visualizzato';

  @override
  String get displayNameEmptyError =>
      'Il nome visualizzato non può essere vuoto';

  @override
  String get displayNameTooLongError =>
      'Il nome visualizzato non può superare i 50 caratteri';

  @override
  String get errorUserNotLoggedIn =>
      'Utente non connesso. Effettua nuovamente l\'accesso.';

  @override
  String get displayNameUpdateSuccess =>
      'Nome visualizzato aggiornato con successo!';

  @override
  String displayNameUpdateError(String error) {
    return 'Impossibile aggiornare il nome visualizzato: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Eliminare l\'immagine?';

  @override
  String get deletePictureConfirmationBody =>
      'Sei sicuro di voler eliminare la tua immagine del profilo?';

  @override
  String get deletePictureSuccess => 'Immagine del profilo eliminata.';

  @override
  String deletePictureError(String error) {
    return 'Impossibile eliminare l\'immagine del profilo: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Impossibile aggiornare l\'immagine del profilo: $error';
  }

  @override
  String get updatePictureSuccess =>
      'Immagine del profilo aggiornata con successo!';

  @override
  String get deletePictureTooltip => 'Elimina immagine';

  @override
  String get account => 'Account';

  @override
  String get settingsBrewingMethodsTitle =>
      'Metodi di preparazione nella schermata principale';

  @override
  String get filter => 'Filtro';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get dateAdded => 'Data di aggiunta';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Icona dell\'app';

  @override
  String get settingsAppIconDefault => 'Predefinito';

  @override
  String get settingsAppIconLegacy => 'Vecchio';

  @override
  String get searchBeans => 'Cerca chicchi...';

  @override
  String get favorites => 'Preferiti';

  @override
  String get searchPrefix => 'Cerca: ';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get noBeansMatchSearch => 'Nessun chicco corrisponde alla tua ricerca';

  @override
  String get clearFilters => 'Cancella filtri';

  @override
  String get farmer => 'Agricoltore';

  @override
  String get farm => 'Azienda agricola';

  @override
  String get enterFarmer => 'Inserisci agricoltore (facoltativo)';

  @override
  String get enterFarm => 'Inserisci azienda agricola (facoltativo)';

  @override
  String get requiredInformation => 'Informazioni necessarie';

  @override
  String get basicDetails => 'Dettagli di base';

  @override
  String get qualityMeasurements => 'Qualità e misure';

  @override
  String get importantDates => 'Date importanti';
}
