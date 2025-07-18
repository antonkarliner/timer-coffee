// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get lastrecipe => 'Receita mais recentemente utilizada:';

  @override
  String get about => 'Sobre';

  @override
  String get author => 'Autor';

  @override
  String get authortext =>
      'O aplicativo Timer.Coffee foi criado por Anton Karliner, um entusiasta do café, especialista em mídia e fotojornalista. Espero que este aplicativo ajude você a desfrutar do seu café. Sinta-se à vontade para contribuir no GitHub.';

  @override
  String get contributors => 'Contribuidores';

  @override
  String get errorLoadingContributors => 'Erro ao carregar contribuidores';

  @override
  String get license => 'Licença';

  @override
  String get licensetext =>
      'Este aplicativo é um software livre: você pode redistribuí-lo e/ou modificá-lo sob os termos da Licença Pública Geral GNU conforme publicada pela Free Software Foundation, seja a versão 3 da Licença, ou (a seu critério) qualquer versão posterior.';

  @override
  String get licensebutton => 'Leia a Licença Pública Geral GNU v3';

  @override
  String get website => 'Site';

  @override
  String get sourcecode => 'Código-fonte';

  @override
  String get support => 'Compre um café para o desenvolvedor';

  @override
  String get allrecipes => 'Todas as Receitas';

  @override
  String get favoriterecipes => 'Receitas Favoritas';

  @override
  String get coffeeamount => 'Quantidade de café (g)';

  @override
  String get wateramount => 'Quantidade de água (ml)';

  @override
  String get watertemp => 'Temperatura da Água';

  @override
  String get grindsize => 'Tamanho da Moagem';

  @override
  String get brewtime => 'Tempo de Preparo';

  @override
  String get recipesummary => 'Resumo da Receita';

  @override
  String get recipesummarynote =>
      'Nota: esta é uma receita básica com quantidades padrão de água e café.';

  @override
  String get preparation => 'Preparação';

  @override
  String get brewingprocess => 'Processo de Preparação';

  @override
  String get step => 'Passo';

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
  String get finishmsg => 'Obrigado por usar o Timer.Coffee! Aproveite seu';

  @override
  String get coffeefact => 'Fato sobre Café';

  @override
  String get home => 'Início';

  @override
  String get appversion => 'Versão do Aplicativo';

  @override
  String get tipsmall => 'Comprar um café pequeno';

  @override
  String get tipmedium => 'Comprar um café médio';

  @override
  String get tiplarge => 'Comprar um café grande';

  @override
  String get supportdevelopment => 'Apoiar o desenvolvimento';

  @override
  String get supportdevmsg =>
      'Suas doações ajudam a cobrir os custos de manutenção (como licenças de desenvolvedor, por exemplo). Elas também me permitem experimentar mais dispositivos de preparação de café e adicionar mais receitas ao aplicativo.';

  @override
  String get supportdevtnx => 'Obrigado por considerar uma doação!';

  @override
  String get donationok => 'Obrigado!';

  @override
  String get donationtnx =>
      'Realmente aprecio seu apoio! Desejo-lhe muitos ótimos cafés! ☕️';

  @override
  String get donationerr => 'Erro';

  @override
  String get donationerrmsg =>
      'Erro ao processar a compra, por favor, tente novamente.';

  @override
  String get sharemsg => 'Confira esta receita:';

  @override
  String get finishbrew => 'Finalizar';

  @override
  String get settings => 'Configurações';

  @override
  String get settingstheme => 'Tema';

  @override
  String get settingsthemelight => 'Claro';

  @override
  String get settingsthemedark => 'Escuro';

  @override
  String get settingsthemesystem => 'Sistema';

  @override
  String get settingslang => 'Idioma';

  @override
  String get sweet => 'Doce';

  @override
  String get balance => 'Equilíbrio';

  @override
  String get acidic => 'Ácido';

  @override
  String get light => 'Leve';

  @override
  String get strong => 'Forte';

  @override
  String get slidertitle => 'Use os controles deslizantes para ajustar o sabor';

  @override
  String get whatsnewtitle => 'O que há de novo';

  @override
  String get whatsnewclose => 'Fechar';

  @override
  String get seasonspecials => 'Especiais de Temporada';

  @override
  String get snow => 'Neve';

  @override
  String get noFavoriteRecipesMessage =>
      'Sua lista de receitas favoritas está atualmente vazia. Comece a explorar e a preparar para descobrir seus favoritos!';

  @override
  String get explore => 'Descobrir';

  @override
  String get dateFormat => 'd \'de\' MMM \'de\' yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Diário de Preparo';

  @override
  String get brewdiarynotfound => 'Nenhuma entrada encontrada';

  @override
  String get beans => 'Grãos';

  @override
  String get roaster => 'Torrador';

  @override
  String get rating => 'Classificação';

  @override
  String get notes => 'Notas';

  @override
  String get statsscreen => 'Estatísticas de Café';

  @override
  String get yourStats => 'Suas estatísticas';

  @override
  String get coffeeBrewed => 'Café preparado:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Receitas mais utilizadas:';

  @override
  String get globalStats => 'Estatísticas globais';

  @override
  String get unknownRecipe => 'Receita Desconhecida';

  @override
  String get noData => 'Sem dados';

  @override
  String error(Object error) {
    return 'Erro: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Alguém acabou de preparar $recipeName';
  }

  @override
  String get timePeriodToday => 'Hoje';

  @override
  String get timePeriodThisWeek => 'Esta Semana';

  @override
  String get timePeriodThisMonth => 'Este Mês';

  @override
  String get timePeriodCustom => 'Personalizado';

  @override
  String get statsFor => 'Estatísticas para ';

  @override
  String get homescreenbrewcoffee => 'Prepare café';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Mais';

  @override
  String get addBeans => 'Adicionar grãos';

  @override
  String get removeBeans => 'Remover grãos';

  @override
  String get name => 'Nome';

  @override
  String get origin => 'Origem';

  @override
  String get details => 'Detalhes';

  @override
  String get coffeebeans => 'Grãos de Café';

  @override
  String get loading => 'Carregando';

  @override
  String get nocoffeebeans => 'Nenhum grão de café encontrado';

  @override
  String get delete => 'Excluir';

  @override
  String get confirmDeleteTitle => 'Excluir entrada?';

  @override
  String get confirmDeleteMessage =>
      'Tem certeza de que deseja excluir esta entrada? Esta ação não pode ser desfeita.';

  @override
  String get removeFavorite => 'Remover dos favoritos';

  @override
  String get addFavorite => 'Adicionar aos favoritos';

  @override
  String get toggleEditMode => 'Alternar modo de edição';

  @override
  String get coffeeBeansDetails => 'Detalhes dos Grãos de Café';

  @override
  String get edit => 'Editar';

  @override
  String get coffeeBeansNotFound => 'Grãos de café não encontrados';

  @override
  String get geographyTerroir => 'Geografia/Terroir';

  @override
  String get variety => 'Variedade';

  @override
  String get region => 'Região';

  @override
  String get elevation => 'Altitude';

  @override
  String get harvestDate => 'Data da Colheita';

  @override
  String get processing => 'Processamento';

  @override
  String get processingMethod => 'Método de Processamento';

  @override
  String get roastDate => 'Data de Torrefação';

  @override
  String get roastLevel => 'Nível de Torrefação';

  @override
  String get cuppingScore => 'Pontuação da Prova';

  @override
  String get flavorProfile => 'Perfil de Sabor';

  @override
  String get tastingNotes => 'Notas de Degustação';

  @override
  String get additionalNotes => 'Notas Adicionais';

  @override
  String get noCoffeeBeans => 'Nenhum grão de café encontrado';

  @override
  String get editCoffeeBeans => 'Editar Grãos de Café';

  @override
  String get addCoffeeBeans => 'Adicionar Grãos de Café';

  @override
  String get showImagePicker => 'Mostrar Seletor de Imagens';

  @override
  String get pleaseNote => 'Observação:';

  @override
  String get firstTimePopupMessage =>
      '1. Usamos serviços externos para processar imagens. Ao continuar, você concorda com isso.\n2. Embora não armazenemos suas imagens, evite incluir quaisquer dados pessoais.\n3. O reconhecimento de imagem está atualmente limitado a 10 tokens por mês (1 token = 1 imagem). Esse limite pode mudar no futuro.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Tirar uma foto';

  @override
  String get selectFromPhotos => 'Selecionar das fotos';

  @override
  String get takeAdditionalPhoto => 'Tirar outra foto?';

  @override
  String get no => 'Não';

  @override
  String get yes => 'Sim';

  @override
  String get selectedImages => 'Imagens Selecionadas';

  @override
  String get selectedImage => 'Imagem Selecionada';

  @override
  String get backToSelection => 'Voltar à Seleção';

  @override
  String get next => 'Próximo';

  @override
  String get unexpectedErrorOccurred => 'Ocorreu um erro inesperado';

  @override
  String get tokenLimitReached =>
      'Desculpe, você atingiu seu limite de tokens para reconhecimento de imagem este mês';

  @override
  String get noCoffeeLabelsDetected =>
      'Nenhum rótulo de café detectado. Tente com outra imagem.';

  @override
  String get collectedInformation => 'Informação coletada';

  @override
  String get enterRoaster => 'Digite a torrefação';

  @override
  String get enterName => 'Digite o nome';

  @override
  String get enterOrigin => 'Digite a origem';

  @override
  String get optional => 'Opcional';

  @override
  String get enterVariety => 'Digite a variedade';

  @override
  String get enterProcessingMethod => 'Digite o método de processamento';

  @override
  String get enterRoastLevel => 'Digite o nível de torrefação';

  @override
  String get enterRegion => 'Digite a região';

  @override
  String get enterTastingNotes => 'Digite as notas de degustação';

  @override
  String get enterElevation => 'Digite a altitude';

  @override
  String get enterCuppingScore => 'Digite a pontuação da prova';

  @override
  String get enterNotes => 'Digite as notas';

  @override
  String get selectHarvestDate => 'Selecione a Data da Colheita';

  @override
  String get selectRoastDate => 'Selecione a Data de Torrefação';

  @override
  String get selectDate => 'Selecione a data';

  @override
  String get save => 'Salvar';

  @override
  String get fillRequiredFields =>
      'Por favor, preencha todos os campos obrigatórios.';

  @override
  String get analyzing => 'Analisando';

  @override
  String get errorMessage => 'Erro';

  @override
  String get selectCoffeeBeans => 'Selecionar Grãos de Café';

  @override
  String get addNewBeans => 'Adicionar Novos Grãos';

  @override
  String get favorite => 'Favorito';

  @override
  String get notFavorite => 'Não Favorito';

  @override
  String get myBeans => 'Meus grãos';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get signInWithApple => 'Entrar com a Apple';

  @override
  String get signInSuccessful => 'Entrada com a Apple realizada com sucesso';

  @override
  String get signInError => 'Erro ao entrar com a Apple';

  @override
  String get signInWithGoogle => 'Entrar com o Google';

  @override
  String get signOutSuccessful => 'Saída realizada com sucesso';

  @override
  String get signInSuccessfulGoogle =>
      'Entrar com o Google realizado com sucesso';

  @override
  String get signInWithEmail => 'Entrar com e-mail';

  @override
  String get enterEmail => 'Digite seu e-mail';

  @override
  String get emailHint => 'exemplo@email.com';

  @override
  String get cancel => 'Cancelar';

  @override
  String get sendMagicLink => 'Enviar link mágico';

  @override
  String get magicLinkSent => 'Link mágico enviado! Verifique seu e-mail.';

  @override
  String get sendOTP => 'Enviar OTP';

  @override
  String get otpSent => 'OTP enviado para seu e-mail';

  @override
  String get otpSendError => 'Erro ao enviar OTP';

  @override
  String get enterOTP => 'Insira o OTP';

  @override
  String get otpHint => 'Insira o código de 6 dígitos';

  @override
  String get verify => 'Verificar';

  @override
  String get signInSuccessfulEmail => 'O login foi bem-sucedido';

  @override
  String get invalidOTP => 'OTP inválido';

  @override
  String get otpVerificationError => 'Erro ao verificar OTP';

  @override
  String get success => 'Sucesso!';

  @override
  String get otpSentMessage =>
      'Um código OTP está sendo enviado para seu e-mail. Insira-o abaixo quando recebê-lo.';

  @override
  String get otpHint2 => 'Insira o código aqui';

  @override
  String get signInCreate => 'Entrar / Criar conta';

  @override
  String get accountManagement => 'Gerenciar conta';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountWarning =>
      'Cuidado: se você escolher continuar, nós excluiremos sua conta e dados relacionados dos nossos servidores. A cópia local dos dados permanecerá no dispositivo, mas se você quiser excluí-la também, basta desinstalar o aplicativo. Para reativar a sincronização, você precisará criar uma conta novamente';

  @override
  String get deleteAccountConfirmation => 'Conta excluída com sucesso';

  @override
  String get accountDeleted => 'Conta excluída';

  @override
  String get accountDeletionError =>
      'Erro ao excluir sua conta. Tente novamente';

  @override
  String get deleteAccountTitle => 'Importante';

  @override
  String get selectBeans => 'Selecione os grãos';

  @override
  String get all => 'Todos';

  @override
  String get selectRoaster => 'Selecionar Torrefação';

  @override
  String get selectOrigin => 'Selecionar Origem';

  @override
  String get resetFilters => 'Redefinir Filtros';

  @override
  String get showFavoritesOnly => 'Mostrar apenas favoritos';

  @override
  String get apply => 'Aplicar';

  @override
  String get selectSize => 'Selecione o tamanho';

  @override
  String get sizeStandard => 'Normal';

  @override
  String get sizeMedium => 'Médio';

  @override
  String get sizeXL => 'Extra Grande';

  @override
  String get yearlyStatsAppBarTitle => 'Meu Ano com o Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Olá! Obrigado por fazer parte do universo Timer.Coffee este ano!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Primeiro, o básico.\nVocê preparou um pouco de café este ano$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Para ser mais preciso,\nvocê preparou $liters litros de café em 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Você usou grãos de $roasterCount torrefações';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Suas 3 principais torrefações foram:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'O café levou você a uma viagem\nao redor do mundo$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Você experimentou grãos de café\nde $originCount países!';
  }

  @override
  String get yearlyStatsStory7Part1 =>
      'Você não estava a preparar café sozinho…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...mas com utilizadores de outros 110\npaíses em 6 continentes!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Você se manteve fiel a si mesmo e usou apenas estes $count métodos de preparo este ano:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Você estava descobrindo novos sabores e usou $count métodos de preparo este ano:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Você foi um verdadeiro descobridor de café e usou $count métodos de preparo este ano:';
  }

  @override
  String get yearlyStatsStory9Text => 'Há muito mais para descobrir!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Suas 3 principais receitas em 2024 foram$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Até 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Demonstre algum amor ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Doar';

  @override
  String get yearlyStatsActionShare => 'Compartilhe seu progresso';

  @override
  String get yearlyStatsUnknown => 'Desconhecido';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Falha ao compartilhar: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Meu ano com o Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes =>
      'Minhas 3 melhores receitas:';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'Meus 3 melhores torrefadores:';

  @override
  String get yearlyStatsFailedToLike =>
      'Falha ao curtir. Por favor, tente novamente.';

  @override
  String get labelCoffeeBrewed => 'Cafés preparados';

  @override
  String get labelTastedBeansBy => 'Grãos experimentados de';

  @override
  String get labelDiscoveredCoffeeFrom => 'Cafés descobertos de';

  @override
  String get labelUsedBrewingMethods => 'Utilizado';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'torrefadores',
      one: 'torrefador',
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
      other: 'métodos de preparo',
      one: 'método de preparo',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Editar Receita';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Criar Receita';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Passos da Receita';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nome da Receita';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Descrição Curta';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Método de Preparo';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Quantidade de Café (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Quantidade de Água (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Temperatura da Água (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Tamanho da Moagem';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Tempo Total de Preparo:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minutos';

  @override
  String get recipeCreationScreenSecondsLabel => 'Segundos';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Passo de Preparação';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Passo de Preparo $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Descrição do Passo';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Tempo do Passo: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Por favor, insira um nome para a receita';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Por favor, insira uma descrição curta';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Por favor, selecione um método de preparo';

  @override
  String get recipeCreationScreenRequiredValidator => 'Obrigatório';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Número inválido';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Por favor, insira uma descrição para o passo';

  @override
  String get recipeCreationScreenContinueButton =>
      'Continuar para os Passos da Receita';

  @override
  String get recipeCreationScreenAddStepButton => 'Adicionar Passo';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Salvar Receita';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Receita atualizada com sucesso';

  @override
  String get recipeCreationScreenSaveSuccess => 'Receita salva com sucesso';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Erro ao salvar receita: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'gramas';

  @override
  String get unitMillilitersLong => 'mililitros';

  @override
  String get recipeCopySuccess => 'Receita copiada com sucesso!';

  @override
  String recipeCopyError(String error) {
    return 'Erro ao copiar a receita: $error';
  }

  @override
  String get createRecipe => 'Criar receita';

  @override
  String errorSyncingData(Object error) {
    return 'Erro ao sincronizar dados: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Erro ao sair: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Preparação';

  @override
  String get loadingEllipsis => 'Carregando...';

  @override
  String get recipeDeletedSuccess => 'Receita excluída com sucesso';

  @override
  String recipeDeleteError(Object error) {
    return 'Falha ao excluir receita: $error';
  }

  @override
  String get noRecipesFound => 'Nenhuma receita encontrada';

  @override
  String recipeLoadError(Object error) {
    return 'Falha ao carregar receita: $error';
  }

  @override
  String get unknownBrewingMethod => 'Método de preparo desconhecido';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Falha ao carregar receita copiada para edição.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operação falhou.';

  @override
  String get notProvided => 'Não fornecido';

  @override
  String get recipeUpdateFailedFetch =>
      'Falha ao buscar dados atualizados da receita.';

  @override
  String get recipeImportSuccess => 'Receita importada com sucesso!';

  @override
  String get recipeImportFailedSave => 'Falha ao salvar receita importada.';

  @override
  String get recipeImportFailedFetch =>
      'Falha ao buscar dados da receita para importação.';

  @override
  String get recipeNotImported => 'Receita não importada.';

  @override
  String get recipeNotFoundCloud =>
      'Receita não encontrada na nuvem ou não é pública.';

  @override
  String get recipeLoadErrorGeneric => 'Erro ao carregar receita.';

  @override
  String get recipeUpdateAvailableTitle => 'Atualização Disponível';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Uma versão mais recente de \'$recipeName\' está disponível online. Atualizar?';
  }

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get dialogUpdate => 'Atualizar';

  @override
  String get recipeImportTitle => 'Importar Receita';

  @override
  String recipeImportBody(String recipeName) {
    return 'Deseja importar a receita \'$recipeName\' da nuvem?';
  }

  @override
  String get dialogImport => 'Importar';

  @override
  String get moderationReviewNeededTitle => 'Revisão de Moderação Necessária';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'A(s) seguinte(s) receita(s) requer(em) revisão devido a problemas de moderação de conteúdo: $recipeNames';
  }

  @override
  String get dismiss => 'Dispensar';

  @override
  String get reviewRecipeButton => 'Revisar Receita';

  @override
  String get signInRequiredTitle => 'Login Necessário';

  @override
  String get signInRequiredBodyShare =>
      'Você precisa fazer login para compartilhar suas próprias receitas.';

  @override
  String get syncSuccess => 'Sincronização bem-sucedida!';

  @override
  String get tooltipEditRecipe => 'Editar Receita';

  @override
  String get tooltipCopyRecipe => 'Copiar Receita';

  @override
  String get tooltipShareRecipe => 'Compartilhar Receita';

  @override
  String get signInRequiredSnackbar => 'Login Necessário';

  @override
  String get moderationErrorFunction =>
      'Falha na verificação de moderação de conteúdo.';

  @override
  String get moderationReasonDefault => 'Conteúdo sinalizado para revisão.';

  @override
  String get moderationFailedTitle => 'Moderação Falhou';

  @override
  String moderationFailedBody(String reason) {
    return 'Esta receita não pode ser compartilhada porque: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Erro ao compartilhar receita: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName no Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Não foi possível verificar o status do conteúdo. Salvo localmente, será verificado na próxima sincronização.';

  @override
  String get saveLocallyModerationFailedTitle => 'Alterações Salvas Localmente';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Suas alterações locais foram salvas, mas a versão pública não pôde ser atualizada devido à moderação de conteúdo: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Editar Receita Importada';

  @override
  String get editImportedRecipeBody =>
      'Esta é uma receita importada. Editá-la criará uma nova cópia independente. Deseja continuar?';

  @override
  String get editImportedRecipeButtonCopy => 'Criar Cópia e Editar';

  @override
  String get editImportedRecipeButtonCancel => 'Cancelar';

  @override
  String get editDisplayNameTitle => 'Editar Nome de Exibição';

  @override
  String get displayNameHint => 'Insira seu nome de exibição';

  @override
  String get displayNameEmptyError => 'O nome de exibição não pode estar vazio';

  @override
  String get displayNameTooLongError =>
      'O nome de exibição não pode exceder 50 caracteres';

  @override
  String get errorUserNotLoggedIn =>
      'Usuário não conectado. Faça login novamente.';

  @override
  String get displayNameUpdateSuccess =>
      'Nome de exibição atualizado com sucesso!';

  @override
  String displayNameUpdateError(String error) {
    return 'Falha ao atualizar o nome de exibição: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Excluir Imagem?';

  @override
  String get deletePictureConfirmationBody =>
      'Tem certeza de que deseja excluir sua foto de perfil?';

  @override
  String get deletePictureSuccess => 'Foto de perfil excluída.';

  @override
  String deletePictureError(String error) {
    return 'Falha ao excluir a foto de perfil: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Falha ao atualizar a foto de perfil: $error';
  }

  @override
  String get updatePictureSuccess => 'Foto de perfil atualizada com sucesso!';

  @override
  String get deletePictureTooltip => 'Excluir Imagem';

  @override
  String get account => 'Conta';

  @override
  String get settingsBrewingMethodsTitle =>
      'Métodos de preparo na tela inicial';

  @override
  String get filter => 'Filtrar';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get dateAdded => 'Data adicionada';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Ícone da aplicação';

  @override
  String get settingsAppIconDefault => 'Padrão';

  @override
  String get settingsAppIconLegacy => 'Antigo';

  @override
  String get searchBeans => 'Pesquisar grãos...';

  @override
  String get favorites => 'Favoritos';

  @override
  String get searchPrefix => 'Pesquisar: ';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get noBeansMatchSearch => 'Nenhum grão corresponde à sua pesquisa';

  @override
  String get clearFilters => 'Limpar filtros';

  @override
  String get farmer => 'Agricultor';

  @override
  String get farm => 'Fazenda de café';

  @override
  String get enterFarmer => 'Digite o agricultor';

  @override
  String get enterFarm => 'Digite a fazenda de café';
}
