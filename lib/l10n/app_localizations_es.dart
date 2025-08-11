// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Estadísticas de granos';

  @override
  String get totalBeansBrewedLabel => 'Total de granos preparados';

  @override
  String get newBeansTriedLabel => 'Nuevos granos probados';

  @override
  String get originsExploredLabel => 'Orígenes explorados';

  @override
  String get regionsExploredLabel => 'Regiones exploradas';

  @override
  String get newRoastersDiscoveredLabel => 'Nuevos tostadores descubiertos';

  @override
  String get favoriteRoastersLabel => 'Tostadores favoritos';

  @override
  String get topOriginsLabel => 'Orígenes destacados';

  @override
  String get topRegionsLabel => 'Regiones destacadas';

  @override
  String get lastrecipe => 'Receta más recientemente utilizada:';

  @override
  String get userRecipesTitle => 'Tus recetas';

  @override
  String get userRecipesSectionCreated => 'Creadas por ti';

  @override
  String get userRecipesSectionImported => 'Importadas por ti';

  @override
  String get userRecipesEmpty => 'No se encontraron recetas';

  @override
  String get userRecipesDeleteTitle => '¿Eliminar receta?';

  @override
  String get userRecipesDeleteMessage => 'Esta acción no se puede deshacer.';

  @override
  String get userRecipesDeleteConfirm => 'Eliminar';

  @override
  String get userRecipesDeleteCancel => 'Cancelar';

  @override
  String get userRecipesSnackbarDeleted => 'Receta eliminada';

  @override
  String get hubUserRecipesTitle => 'Tus recetas';

  @override
  String get hubUserRecipesSubtitle =>
      'Ver y gestionar recetas creadas e importadas';

  @override
  String get hubAccountSubtitle => 'Gestiona tu perfil';

  @override
  String get hubSignInCreateSubtitle =>
      'Inicia sesión para sincronizar recetas y preferencias';

  @override
  String get hubBrewDiarySubtitle =>
      'Consulta tu historial de preparación y añade notas';

  @override
  String get hubBrewStatsSubtitle =>
      'Consulta estadísticas y tendencias de preparación personales y globales';

  @override
  String get hubSettingsSubtitle =>
      'Cambia las preferencias y el comportamiento de la aplicación';

  @override
  String get hubAboutSubtitle => 'Detalles de la app, versión y colaboradores';

  @override
  String get about => 'Acerca de';

  @override
  String get author => 'Autor';

  @override
  String get authortext =>
      'La aplicación Timer.Coffee ha sido creada por Anton Karliner, un entusiasta del café, especialista en medios y fotoperiodista. Espero que esta aplicación te ayude a disfrutar de tu café. Siéntete libre de contribuir en GitHub.';

  @override
  String get contributors => 'Colaboradores';

  @override
  String get errorLoadingContributors => 'Error al cargar los colaboradores';

  @override
  String get license => 'Licencia';

  @override
  String get licensetext =>
      'Esta aplicación es software libre: puedes redistribuirla y/o modificarla bajo los términos de la Licencia Pública General GNU según publicada por la Free Software Foundation, ya sea la versión 3 de la Licencia, o (a tu elección) cualquier versión posterior.';

  @override
  String get licensebutton => 'Leer la Licencia Pública General GNU v3';

  @override
  String get website => 'Sitio web';

  @override
  String get sourcecode => 'Código fuente';

  @override
  String get support => 'Compra un café para el desarrollador';

  @override
  String get allrecipes => 'Todas las recetas';

  @override
  String get favoriterecipes => 'Recetas favoritas';

  @override
  String get coffeeamount => 'Cantidad de café (g)';

  @override
  String get wateramount => 'Cantidad de agua (ml)';

  @override
  String get watertemp => 'Temperatura del agua';

  @override
  String get grindsize => 'Tamaño de molienda';

  @override
  String get brewtime => 'Tiempo de preparación';

  @override
  String get recipesummary => 'Resumen de la receta';

  @override
  String get recipesummarynote =>
      'Nota: esta es una receta básica con cantidades predeterminadas de agua y café.';

  @override
  String get preparation => 'Preparación';

  @override
  String get brewingprocess => 'Proceso de preparación';

  @override
  String get step => 'Paso';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'segundos',
      one: 'segundo',
      zero: 'segundos',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Gracias por usar Timer.Coffee! Disfruta de tu';

  @override
  String get coffeefact => 'Dato sobre el café';

  @override
  String get home => 'Inicio';

  @override
  String get appversion => 'Versión de la aplicación';

  @override
  String get tipsmall => 'Comprar un café pequeño';

  @override
  String get tipmedium => 'Comprar un café mediano';

  @override
  String get tiplarge => 'Comprar un café grande';

  @override
  String get supportdevelopment => 'Apoyar el desarrollo';

  @override
  String get supportdevmsg =>
      'Tus donaciones ayudan a cubrir los costos de mantenimiento (como licencias de desarrollador, por ejemplo). También me permiten probar más dispositivos de preparación de café y agregar más recetas a la aplicación.';

  @override
  String get supportdevtnx => '¡Gracias por considerar donar!';

  @override
  String get donationok => '¡Gracias!';

  @override
  String get donationtnx =>
      '¡Realmente aprecio tu apoyo! ¡Te deseo muchas preparaciones excelentes! ☕️';

  @override
  String get donationerr => 'Error';

  @override
  String get donationerrmsg =>
      'Error al procesar la compra, por favor intenta de nuevo.';

  @override
  String get sharemsg => 'Revisa esta receta:';

  @override
  String get finishbrew => 'Finalizar';

  @override
  String get settings => 'Configuraciones';

  @override
  String get settingstheme => 'Tema';

  @override
  String get settingsthemelight => 'Claro';

  @override
  String get settingsthemedark => 'Oscuro';

  @override
  String get settingsthemesystem => 'Sistema';

  @override
  String get settingslang => 'Idioma';

  @override
  String get sweet => 'Dulce';

  @override
  String get balance => 'Equilibrio';

  @override
  String get acidic => 'Ácido';

  @override
  String get light => 'Ligero';

  @override
  String get strong => 'Fuerte';

  @override
  String get slidertitle =>
      'Usa los controles deslizantes para ajustar el sabor';

  @override
  String get whatsnewtitle => 'Qué hay de nuevo';

  @override
  String get whatsnewclose => 'Cerrar';

  @override
  String get seasonspecials => 'Especiales de Temporada';

  @override
  String get snow => 'Nieve';

  @override
  String get noFavoriteRecipesMessage =>
      'Tu lista de recetas favoritas está actualmente vacía. ¡Comienza a explorar y preparar para descubrir tus favoritos!';

  @override
  String get explore => 'Explorar';

  @override
  String get dateFormat => 'd MMM, yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Diario de Cerveza';

  @override
  String get brewdiarynotfound => 'No se encontraron entradas';

  @override
  String get beans => 'Granos';

  @override
  String get roaster => 'Tostador';

  @override
  String get rating => 'Calificación';

  @override
  String get notes => 'Notas';

  @override
  String get statsscreen => 'Estadísticas de café';

  @override
  String get yourStats => 'Tus estadísticas';

  @override
  String get coffeeBrewed => 'Café preparado:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Recetas más usadas:';

  @override
  String get globalStats => 'Estadísticas globales';

  @override
  String get unknownRecipe => 'Receta desconocida';

  @override
  String get noData => 'Sin datos';

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Alguien acaba de preparar $recipeName';
  }

  @override
  String get timePeriodToday => 'Hoy';

  @override
  String get timePeriodThisWeek => 'Esta semana';

  @override
  String get timePeriodThisMonth => 'Este mes';

  @override
  String get timePeriodCustom => 'Personalizado';

  @override
  String get statsFor => 'Estadísticas de ';

  @override
  String get homescreenbrewcoffee => 'Preparar café';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Más';

  @override
  String get addBeans => 'Añadir granos';

  @override
  String get removeBeans => 'Quitar granos';

  @override
  String get name => 'Nombre';

  @override
  String get origin => 'Origen';

  @override
  String get details => 'Detalles';

  @override
  String get coffeebeans => 'Granos de café';

  @override
  String get loading => 'Cargando';

  @override
  String get nocoffeebeans => 'No se encontraron granos de café';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirmDeleteTitle => '¿Eliminar entrada?';

  @override
  String get confirmDeleteMessage =>
      '¿Está seguro de que desea eliminar esta entrada? Esta acción no se puede deshacer.';

  @override
  String get removeFavorite => 'Eliminar de favoritos';

  @override
  String get addFavorite => 'Añadir a favoritos';

  @override
  String get toggleEditMode => 'Activar/desactivar modo de edición';

  @override
  String get coffeeBeansDetails => 'Detalles de los granos de café';

  @override
  String get edit => 'Editar';

  @override
  String get coffeeBeansNotFound => 'No se encontraron granos de café';

  @override
  String get geographyTerroir => 'Geografía/Terruño';

  @override
  String get variety => 'Variedad';

  @override
  String get region => 'Región';

  @override
  String get elevation => 'Elevación';

  @override
  String get harvestDate => 'Fecha de cosecha';

  @override
  String get processing => 'Procesamiento';

  @override
  String get processingMethod => 'Método de procesamiento';

  @override
  String get roastDate => 'Fecha de tueste';

  @override
  String get roastLevel => 'Nivel de tueste';

  @override
  String get cuppingScore => 'Puntuación de cata';

  @override
  String get flavorProfile => 'Perfil de sabor';

  @override
  String get tastingNotes => 'Notas de cata';

  @override
  String get additionalNotes => 'Notas adicionales';

  @override
  String get noCoffeeBeans => 'No se encontraron granos de café';

  @override
  String get editCoffeeBeans => 'Editar granos de café';

  @override
  String get addCoffeeBeans => 'Añadir granos de café';

  @override
  String get showImagePicker => 'Mostrar selector de imágenes';

  @override
  String get pleaseNote => 'Tenga en cuenta';

  @override
  String get firstTimePopupMessage =>
      '1. Utilizamos servicios externos para procesar imágenes. Al continuar, aceptas esto.\n2. Si bien no almacenamos tus imágenes, evita incluir datos personales.\n3. El reconocimiento de imágenes está actualmente limitado a 10 tokens por mes (1 token = 1 imagen). Este límite puede cambiar en el futuro.';

  @override
  String get ok => 'Aceptar';

  @override
  String get takePhoto => 'Tomar una foto';

  @override
  String get selectFromPhotos => 'Seleccionar de las fotos';

  @override
  String get takeAdditionalPhoto => '¿Tomar otra foto?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Sí';

  @override
  String get selectedImages => 'Imágenes seleccionadas';

  @override
  String get selectedImage => 'Imagen seleccionada';

  @override
  String get backToSelection => 'Volver a la selección';

  @override
  String get next => 'Siguiente';

  @override
  String get unexpectedErrorOccurred => 'Se ha producido un error inesperado';

  @override
  String get tokenLimitReached =>
      'Lo sentimos, has alcanzado tu límite de tokens para el reconocimiento de imágenes este mes';

  @override
  String get noCoffeeLabelsDetected =>
      'No se detectaron etiquetas de café. Prueba con otra imagen.';

  @override
  String get collectedInformation => 'Información recopilada';

  @override
  String get enterRoaster => 'Introducir tostador';

  @override
  String get enterName => 'Introducir nombre';

  @override
  String get enterOrigin => 'Introducir origen';

  @override
  String get optional => 'Opcional';

  @override
  String get enterVariety => 'Introducir variedad';

  @override
  String get enterProcessingMethod => 'Introducir método de procesamiento';

  @override
  String get enterRoastLevel => 'Introducir nivel de tueste';

  @override
  String get enterRegion => 'Introducir región';

  @override
  String get enterTastingNotes => 'Introducir notas de cata';

  @override
  String get enterElevation => 'Introducir elevación';

  @override
  String get enterCuppingScore => 'Introducir puntuación de cata';

  @override
  String get enterNotes => 'Introducir notas';

  @override
  String get selectHarvestDate => 'Seleccionar fecha de cosecha';

  @override
  String get selectRoastDate => 'Seleccionar fecha de tueste';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get save => 'Guardar';

  @override
  String get fillRequiredFields =>
      'Por favor, rellena todos los campos obligatorios.';

  @override
  String get analyzing => 'Analizando';

  @override
  String get errorMessage => 'Error';

  @override
  String get selectCoffeeBeans => 'Seleccionar granos de café';

  @override
  String get addNewBeans => 'Añadir nuevos granos';

  @override
  String get favorite => 'Favorito';

  @override
  String get notFavorite => 'No favorito';

  @override
  String get myBeans => 'Mis granos';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signInWithApple => 'Inicia sesión con Apple';

  @override
  String get signInSuccessful => 'Se inició sesión con Apple correctamente';

  @override
  String get signInError => 'Error al iniciar sesión con Apple';

  @override
  String get signInWithGoogle => 'Inicia sesión con Google';

  @override
  String get signOutSuccessful => 'Cierre de sesión realizado correctamente';

  @override
  String get signInSuccessfulGoogle => 'Inicio de sesión correcto con Google';

  @override
  String get signInWithEmail => 'Iniciar sesión con correo electrónico';

  @override
  String get enterEmail => 'Ingresa tu correo electrónico';

  @override
  String get emailHint => 'ejemplo@correo.com';

  @override
  String get cancel => 'Cancelar';

  @override
  String get sendMagicLink => 'Enviar enlace mágico';

  @override
  String get magicLinkSent =>
      '¡Enlace mágico enviado! Revisa tu correo electrónico.';

  @override
  String get sendOTP => 'Enviar OTP';

  @override
  String get otpSent => 'OTP enviado a su correo electrónico';

  @override
  String get otpSendError => 'Error al enviar OTP';

  @override
  String get enterOTP => 'Ingrese OTP';

  @override
  String get otpHint => 'Ingrese el código de 6 dígitos';

  @override
  String get verify => 'Verificar';

  @override
  String get signInSuccessfulEmail => 'Inicio de sesión exitoso';

  @override
  String get invalidOTP => 'OTP inválido';

  @override
  String get otpVerificationError => 'Error al verificar OTP';

  @override
  String get success => '¡Éxito!';

  @override
  String get otpSentMessage =>
      'Se está enviando un OTP a tu correo electrónico. Por favor, introdúcelo a continuación cuando lo recibas.';

  @override
  String get otpHint2 => 'Escriba aquí el código';

  @override
  String get signInCreate => 'Iniciar sesión / Crear cuenta';

  @override
  String get accountManagement => 'Administración de la cuenta';

  @override
  String get deleteAccount => 'Borrar cuenta';

  @override
  String get deleteAccountWarning =>
      'Tenga en cuenta: si elige continuar, eliminaremos su cuenta y los datos relacionados de nuestros servidores. La copia local de los datos permanecerá en el dispositivo, si también desea eliminarla, simplemente puede eliminar la aplicación. Para volver a habilitar la sincronización, deberá crear una nueva cuenta';

  @override
  String get deleteAccountConfirmation => 'Cuenta eliminada correctamente';

  @override
  String get accountDeleted => 'Cuenta eliminada';

  @override
  String get accountDeletionError =>
      'Error al eliminar su cuenta, inténtelo de nuevo';

  @override
  String get deleteAccountTitle => 'Importante';

  @override
  String get selectBeans => 'Seleccionar granos';

  @override
  String get all => 'Todos';

  @override
  String get selectRoaster => 'Seleccionar tostador';

  @override
  String get selectOrigin => 'Seleccionar origen';

  @override
  String get resetFilters => 'Restablecer filtros';

  @override
  String get showFavoritesOnly => 'Mostrar solo favoritos';

  @override
  String get apply => 'Aplicar';

  @override
  String get selectSize => 'Selecciona tamaño';

  @override
  String get sizeStandard => 'Estándar';

  @override
  String get sizeMedium => 'Mediano';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Mi año con Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      '¡Hola! Gracias por ser parte del universo de Timer.Coffee este año.';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Primero lo primero.\nEste año preparaste café$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Para ser más precisos,\n¡preparaste $liters litros de café en 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Usaste granos de $roasterCount tostadores';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Tus 3 tostadores principales fueron:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'El café te llevó a un viaje\nalrededor del mundo$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return '¡Probaste granos de café\nde $originCount países!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'No estuviste preparando café solo...';

  @override
  String get yearlyStatsStory7Part2 =>
      '...¡sino con usuarios de otros 110\npaíses en 6 continentes!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Te mantuviste fiel a ti mismo y solo usaste estos $count métodos de preparación este año:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Estuviste descubriendo nuevos sabores y usaste $count métodos de preparación este año:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Fuiste un verdadero descubridor de café y usaste $count métodos de preparación este año:';
  }

  @override
  String get yearlyStatsStory9Text => '¡Hay mucho más por descubrir!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Tus 3 recetas principales en 2024 fueron$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => '¡Nos vemos en 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Muestra un poco de amor ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Donar';

  @override
  String get yearlyStatsActionShare => 'Comparte tu progreso';

  @override
  String get yearlyStatsUnknown => 'Desconocido';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'No se pudo compartir: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Mi año con Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes =>
      'Mis 3 recetas principales:';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'Mis 3 tostadores principales:';

  @override
  String get yearlyStatsFailedToLike =>
      'No se pudo dar me gusta. Inténtalo de nuevo.';

  @override
  String get labelCoffeeBrewed => 'Café preparado';

  @override
  String get labelTastedBeansBy => 'Granos probados por';

  @override
  String get labelDiscoveredCoffeeFrom => 'Café descubierto de';

  @override
  String get labelUsedBrewingMethods => 'Métodos utilizados';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tostadores',
      one: 'tostador',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'países',
      one: 'país',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'métodos de preparación',
      one: 'método de preparación',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Editar Receta';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Crear Receta';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Pasos de la Receta';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nombre de la Receta';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Descripción Corta';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Método de Preparación';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Cantidad de Café (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Cantidad de Agua (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Temperatura del Agua (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Tamaño de Molienda';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Tiempo Total de Preparación:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minutos';

  @override
  String get recipeCreationScreenSecondsLabel => 'Segundos';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Paso de Preparación';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Paso de Preparación $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Descripción del Paso';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Tiempo del Paso: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Por favor, introduce un nombre para la receta';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Por favor, introduce una descripción corta';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Por favor, selecciona un método de preparación';

  @override
  String get recipeCreationScreenRequiredValidator => 'Requerido';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Número inválido';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Por favor, introduce una descripción para el paso';

  @override
  String get recipeCreationScreenContinueButton =>
      'Continuar a los Pasos de la Receta';

  @override
  String get recipeCreationScreenAddStepButton => 'Añadir Paso';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Guardar Receta';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Receta actualizada con éxito';

  @override
  String get recipeCreationScreenSaveSuccess => 'Receta guardada con éxito';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Error al guardar la receta: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'gramos';

  @override
  String get unitMillilitersLong => 'mililitros';

  @override
  String get recipeCopySuccess => '¡Receta copiada con éxito!';

  @override
  String recipeCopyError(String error) {
    return 'Error al copiar la receta: $error';
  }

  @override
  String get createRecipe => 'Crear receta';

  @override
  String errorSyncingData(Object error) {
    return 'Error al sincronizar datos: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Error al cerrar sesión: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Preparación';

  @override
  String get loadingEllipsis => 'Cargando...';

  @override
  String get recipeDeletedSuccess => 'Receta eliminada con éxito';

  @override
  String recipeDeleteError(Object error) {
    return 'Error al eliminar la receta: $error';
  }

  @override
  String get noRecipesFound => 'No se encontraron recetas';

  @override
  String recipeLoadError(Object error) {
    return 'Error al cargar la receta: $error';
  }

  @override
  String get unknownBrewingMethod => 'Método de preparación desconocido';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Error al cargar la receta copiada para editar.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operación fallida.';

  @override
  String get notProvided => 'No proporcionado';

  @override
  String get recipeUpdateFailedFetch =>
      'Error al obtener los datos actualizados de la receta.';

  @override
  String get recipeImportSuccess => '¡Receta importada con éxito!';

  @override
  String get recipeImportFailedSave => 'Error al guardar la receta importada.';

  @override
  String get recipeImportFailedFetch =>
      'Error al obtener los datos de la receta para importar.';

  @override
  String get recipeNotImported => 'Receta no importada.';

  @override
  String get recipeNotFoundCloud =>
      'Receta no encontrada en la nube o no es pública.';

  @override
  String get recipeLoadErrorGeneric => 'Error al cargar la receta.';

  @override
  String get recipeUpdateAvailableTitle => 'Actualización disponible';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Hay una versión más reciente de \'$recipeName\' disponible en línea. ¿Actualizar?';
  }

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get dialogUpdate => 'Actualizar';

  @override
  String get recipeImportTitle => 'Importar receta';

  @override
  String recipeImportBody(String recipeName) {
    return '¿Quieres importar la receta \'$recipeName\' de la nube?';
  }

  @override
  String get dialogImport => 'Importar';

  @override
  String get moderationReviewNeededTitle => 'Revisión de moderación necesaria';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'La(s) siguiente(s) receta(s) requiere(n) revisión debido a problemas de moderación de contenido: $recipeNames';
  }

  @override
  String get dismiss => 'Descartar';

  @override
  String get reviewRecipeButton => 'Revisar Receta';

  @override
  String get signInRequiredTitle => 'Inicio de sesión requerido';

  @override
  String get signInRequiredBodyShare =>
      'Necesitas iniciar sesión para compartir tus propias recetas.';

  @override
  String get syncSuccess => '¡Sincronización exitosa!';

  @override
  String get tooltipEditRecipe => 'Editar Receta';

  @override
  String get tooltipCopyRecipe => 'Copiar Receta';

  @override
  String get tooltipShareRecipe => 'Compartir Receta';

  @override
  String get signInRequiredSnackbar => 'Inicio de sesión requerido';

  @override
  String get moderationErrorFunction =>
      'Falló la verificación de moderación de contenido.';

  @override
  String get moderationReasonDefault => 'Contenido marcado para revisión.';

  @override
  String get moderationFailedTitle => 'Moderación Fallida';

  @override
  String moderationFailedBody(String reason) {
    return 'Esta receta no se puede compartir porque: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Error al compartir la receta: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName en Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'No se pudo verificar el estado del contenido. Guardado localmente, se verificará en la próxima sincronización.';

  @override
  String get saveLocallyModerationFailedTitle => 'Cambios Guardados Localmente';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Tus cambios locales se han guardado, pero la versión pública no pudo actualizarse debido a la moderación de contenido: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Editar receta importada';

  @override
  String get editImportedRecipeBody =>
      'Esta es una receta importada. Editarla creará una copia nueva e independiente. ¿Desea continuar?';

  @override
  String get editImportedRecipeButtonCopy => 'Crear copia y editar';

  @override
  String get editImportedRecipeButtonCancel => 'Cancelar';

  @override
  String get editDisplayNameTitle => 'Editar nombre de usuario';

  @override
  String get displayNameHint => 'Introduce tu nombre de usuario';

  @override
  String get displayNameEmptyError =>
      'El nombre de usuario no puede estar vacío';

  @override
  String get displayNameTooLongError =>
      'El nombre de usuario no puede exceder los 50 caracteres';

  @override
  String get errorUserNotLoggedIn =>
      'Usuario no conectado. Por favor, inicia sesión de nuevo.';

  @override
  String get displayNameUpdateSuccess =>
      '¡Nombre de usuario actualizado correctamente!';

  @override
  String displayNameUpdateError(String error) {
    return 'Error al actualizar el nombre de usuario: $error';
  }

  @override
  String get deletePictureConfirmationTitle => '¿Eliminar imagen?';

  @override
  String get deletePictureConfirmationBody =>
      '¿Estás seguro de que quieres eliminar tu foto de perfil?';

  @override
  String get deletePictureSuccess => 'Foto de perfil eliminada.';

  @override
  String deletePictureError(String error) {
    return 'Error al eliminar la foto de perfil: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Error al actualizar la foto de perfil: $error';
  }

  @override
  String get updatePictureSuccess =>
      '¡Foto de perfil actualizada correctamente!';

  @override
  String get deletePictureTooltip => 'Eliminar imagen';

  @override
  String get account => 'Cuenta';

  @override
  String get settingsBrewingMethodsTitle =>
      'Métodos de preparación en la pantalla de inicio';

  @override
  String get filter => 'Filtro';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get dateAdded => 'Fecha de adición';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Icono de la aplicación';

  @override
  String get settingsAppIconDefault => 'Predeterminado';

  @override
  String get settingsAppIconLegacy => 'Antiguo';

  @override
  String get searchBeans => 'Buscar granos...';

  @override
  String get favorites => 'Favoritos';

  @override
  String get searchPrefix => 'Buscar: ';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get noBeansMatchSearch => 'Ningún grano coincide con su búsqueda';

  @override
  String get clearFilters => 'Borrar filtros';

  @override
  String get farmer => 'Agricultor';

  @override
  String get farm => 'Finca';

  @override
  String get enterFarmer => 'Ingresar agricultor (opcional)';

  @override
  String get enterFarm => 'Ingresar finca (opcional)';

  @override
  String get requiredInformation => 'Información necesaria';

  @override
  String get basicDetails => 'Datos básicos';

  @override
  String get qualityMeasurements => 'Medidas de calidad';

  @override
  String get importantDates => 'Fechas importantes';

  @override
  String get brewStats => 'Estadísticas de preparación';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get showLess => 'Mostrar menos';
}
