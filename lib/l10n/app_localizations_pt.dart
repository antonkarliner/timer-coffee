// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Estatísticas dos grãos';

  @override
  String get totalBeansBrewedLabel => 'Total de grãos utilizados';

  @override
  String get newBeansTriedLabel => 'Novos grãos experimentados';

  @override
  String get originsExploredLabel => 'Origens exploradas';

  @override
  String get regionsExploredLabel => 'Europa';

  @override
  String get newRoastersDiscoveredLabel => 'Novas torrefações descobertas';

  @override
  String get favoriteRoastersLabel => 'Torrefações favoritas';

  @override
  String get topOriginsLabel => 'Principais origens';

  @override
  String get topRegionsLabel => 'Principais regiões';

  @override
  String get lastrecipe => 'Receita mais recentemente utilizada:';

  @override
  String get userRecipesTitle => 'Suas receitas';

  @override
  String get userRecipesSectionCreated => 'Criadas por você';

  @override
  String get userRecipesSectionImported => 'Importadas por você';

  @override
  String get userRecipesEmpty => 'Nenhuma receita encontrada';

  @override
  String get userRecipesDeleteTitle => 'Excluir receita?';

  @override
  String get userRecipesDeleteMessage => 'Esta ação não pode ser desfeita.';

  @override
  String get userRecipesDeleteConfirm => 'Excluir';

  @override
  String get userRecipesDeleteCancel => 'Cancelar';

  @override
  String get userRecipesSnackbarDeleted => 'Receita excluída';

  @override
  String get hubUserRecipesTitle => 'Suas receitas';

  @override
  String get hubUserRecipesSubtitle =>
      'Ver e gerenciar receitas criadas e importadas';

  @override
  String get hubAccountSubtitle => 'Gerencie seu perfil';

  @override
  String get hubSignInCreateSubtitle =>
      'Faça login para sincronizar receitas e preferências';

  @override
  String get hubBrewDiarySubtitle =>
      'Veja seu histórico de preparo e adicione notas';

  @override
  String get hubBrewStatsSubtitle =>
      'Veja estatísticas e tendências de preparo pessoais e globais';

  @override
  String get hubSettingsSubtitle =>
      'Altere preferências e comportamento do app';

  @override
  String get hubAboutSubtitle => 'Detalhes do app, versão e contribuidores';

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
  String get roaster => 'Torrefação';

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
  String error(String error) {
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
  String get homescreenbrewcoffee => 'Preparar café';

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
  String get recipeDuplicateConfirmTitle => 'Duplicar receita?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Isto criará uma cópia da sua receita que você pode editar independentemente. Deseja continuar?';

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
  String get basicInformation => 'Dados básicos';

  @override
  String get geographyTerroir => 'Geografia/Terroir';

  @override
  String get variety => 'Variedade';

  @override
  String get region => 'América do Norte';

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
  String get inventory => 'Estoque';

  @override
  String get amountLeft => 'Quantidade restante';

  @override
  String get enterAmountLeft => 'Digite a quantidade restante';

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
  String get signInErrorGoogle => 'Erro ao entrar com a Google';

  @override
  String get signInWithGoogle => 'Entrar com o Google';

  @override
  String get signOutSuccessful => 'Saída realizada com sucesso';

  @override
  String get signOutConfirmationTitle => 'Tem certeza de que deseja sair?';

  @override
  String get signOutConfirmationMessage =>
      'A sincronização na nuvem vai parar de funcionar. Entre novamente para retomar.';

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
  String get yearlyStats25AppBarTitle => 'Seu ano com Timer.Coffee – 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee em 2025';

  @override
  String get yearlyStats25Slide1Title => 'Seu ano com Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'Toque para ver como você preparou café em 2025';

  @override
  String get yearlyStats25Slide2Intro => 'Juntos, nós preparamos café...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count vezes';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'Isso dá cerca de $liters litros de café';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'O suficiente para dar uma xícara de café para todo mundo em Cambridge, Reino Unido (os estudantes seriam especialmente gratos).';

  @override
  String get yearlyStats25Slide3Title => 'E você?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'Você preparou café $brews vezes com Timer.Coffee este ano. No total, $liters litros de café!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'Você está entre o top $topPct% de quem prepara café!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'Lembra do dia em que você preparou mais café este ano?';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'Lembra dos dias em que você preparou mais café este ano?';

  @override
  String get yearlyStats25Slide4TitleBrewTime =>
      'Seu tempo de preparo este ano';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'Raspe para revelar';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preparos',
      one: '1 preparo',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'Cerca de $liters litros nesse dia';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
      String mostRecent, String brewsLabel) {
    return 'Mais recente: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'Você passou $timeLabel preparando café';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => 'Tempo bem aproveitado';

  @override
  String get yearlyStats25Slide5Title => 'É assim que você prepara';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'Métodos favoritos:';

  @override
  String get yearlyStats25Slide5NoMethods => 'Nenhum método ainda';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'Principais receitas:';

  @override
  String get yearlyStats25Slide5NoRecipes => 'Nenhuma receita ainda';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'preparos',
      one: 'preparo',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'Você descobriu $count torrefações este ano:';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => 'Nenhuma torrefação ainda';

  @override
  String get yearlyStats25Slide7Title => 'Beber café pode te levar longe…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'Você descobriu $count origens este ano:';
  }

  @override
  String get yearlyStats25Others => '...e outras';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'Este ano, usuários do Timer.Coffee usaram grãos de $countries países\ne registraram $roasters torrefações diferentes.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'Que tal continuar registrando seus pacotes de grãos?';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'Talvez seja hora de você entrar e registrar seus grãos também?';

  @override
  String get yearlyStats25FallbackActionHasBeans =>
      'Continuar adicionando grãos';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'Adicionar seu primeiro pacote de grãos';

  @override
  String get yearlyStats25ContinueButton => 'Continuar';

  @override
  String get yearlyStats25PostcardTitle =>
      'Envie um desejo de Ano-Novo para outro amante do café.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'Opcional. Seja gentil. Nada de informações pessoais.';

  @override
  String get yearlyStats25PostcardHint => 'Feliz Ano-Novo e ótimos cafés!';

  @override
  String get yearlyStats25PostcardSending => 'Enviando...';

  @override
  String get yearlyStats25PostcardSend => 'Enviar';

  @override
  String get yearlyStats25PostcardSkip => 'Pular';

  @override
  String get yearlyStats25PostcardReceivedTitle =>
      'Um desejo de outro amante do café';

  @override
  String get yearlyStats25PostcardErrorLength => 'Digite 2–160 caracteres.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'Não foi possível enviar. Tente novamente.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'Não foi possível enviar. Tente outra mensagem.';

  @override
  String get yearlyStats25CtaTitle => 'Vamos preparar algo incrível em 2026!';

  @override
  String get yearlyStats25CtaSubtitle => 'Aqui vão algumas ideias:';

  @override
  String get yearlyStats25CtaExplorePrefix => 'Explore ofertas na ';

  @override
  String get yearlyStats25CtaGiftBox => 'Caixa de Presentes de Férias';

  @override
  String get yearlyStats25CtaDonate => 'Doar';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' para ajudar o Timer.Coffee a crescer no próximo ano';

  @override
  String get yearlyStats25CtaFollowPrefix => 'Siga-nos no ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'Compartilhar meu progresso';

  @override
  String get yearlyStats25CtaShareHint =>
      'Não se esqueça de marcar @timercoffeeapp';

  @override
  String get yearlyStats25AppBarTooltipResume => 'Retomar';

  @override
  String get yearlyStats25AppBarTooltipPause => 'Pausar';

  @override
  String get yearlyStats25ShareError =>
      'Não foi possível compartilhar o resumo. Tente novamente.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours h';
  }

  @override
  String get yearlyStats25ShareTitle => 'Meu ano 2025 com Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'Preparei ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' vezes e ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' litros de café';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'Usei grãos de ';

  @override
  String get yearlyStats25ShareRoastersSuffix => ' torrefações';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'Descobri ';

  @override
  String get yearlyStats25ShareOriginsSuffix => ' origens de café';

  @override
  String get yearlyStats25ShareMethodsTitle =>
      'Meus métodos de preparo favoritos:';

  @override
  String get yearlyStats25ShareRecipesTitle => 'Minhas principais receitas:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

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
  String get recipeDuplicateSuccess => 'Receita duplicada com sucesso!';

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
  String get dialogDuplicate => 'Duplicar';

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
  String get tooltipDuplicateRecipe => 'Duplicar Receita';

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

  @override
  String get requiredInformation => 'Informações necessárias';

  @override
  String get basicDetails => 'Detalhes básicos';

  @override
  String get qualityMeasurements => 'Qualidade e medições';

  @override
  String get importantDates => 'Datas importantes';

  @override
  String get brewStats => 'Estatísticas de preparo';

  @override
  String get showMore => 'Mostrar mais';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get unpublishRecipeDialogTitle => 'Tornar a receita privada';

  @override
  String get unpublishRecipeDialogMessage =>
      'Aviso: Tornar esta receita privada irá:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Removê-la dos resultados de pesquisa públicos';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Impedir que novos utilizadores a importem';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Os utilizadores que já a importaram irão manter as suas cópias';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Manter pública';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Tornar privada';

  @override
  String get recipeUnpublishSuccess =>
      'Publicação da receita cancelada com sucesso';

  @override
  String recipeUnpublishError(String error) {
    return 'Erro ao cancelar a publicação da receita: $error';
  }

  @override
  String get recipePublicTooltip =>
      'A receita é pública - toque para a tornar privada';

  @override
  String get recipePrivateTooltip =>
      'A receita é privada - partilhe para a tornar pública';

  @override
  String get fieldClearButtonTooltip => 'Limpar';

  @override
  String get dateFieldClearButtonTooltip => 'Limpar data';

  @override
  String get chipInputDuplicateError => 'Esta tag já foi adicionada';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Número máximo de tags atingido ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Adicionar uma tag...';

  @override
  String get unitFieldRequiredError => 'Este campo é obrigatório';

  @override
  String get unitFieldInvalidNumberError =>
      'Por favor, insira um número válido';

  @override
  String unitFieldMinValueError(Object min) {
    return 'O valor deve ser pelo menos $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'O valor deve ser no máximo $max';
  }

  @override
  String get numericFieldRequiredError => 'Este campo é obrigatório';

  @override
  String get numericFieldInvalidNumberError =>
      'Por favor, insira um número válido';

  @override
  String numericFieldMinValueError(Object min) {
    return 'O valor deve ser pelo menos $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'O valor deve ser no máximo $max';
  }

  @override
  String get dropdownSearchHintText => 'Digite para pesquisar...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Erro ao carregar sugestões: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Nenhum resultado encontrado';

  @override
  String get dropdownSearchLoading => 'Pesquisando...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Usar \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Obrigatório';

  @override
  String get inventoryWeightExample => 'ex. 250.5';

  @override
  String get unsavedChangesTitle => 'Alterações não salvas';

  @override
  String get unsavedChangesMessage =>
      'Você tem alterações não salvas. Tem certeza de que deseja descartá-las?';

  @override
  String get unsavedChangesStay => 'Ficar';

  @override
  String get unsavedChangesDiscard => 'Descartar';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return 'Adicionado $amount$unit de volta para $beanName. Novo peso: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return 'Subtraído $amount$unit de $beanName. Novo peso: $newWeight$unit';
  }

  @override
  String get notifications => 'Notificações';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Desativado nas configurações do sistema';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link';

  @override
  String get notificationsDisabledDialogTitle =>
      'Notificações desativadas nas configurações do sistema';

  @override
  String get notificationsDisabledDialogContent =>
      'Você desativou as notificações nas configurações do seu dispositivo. Para ativar as notificações, por favor, abra as configurações do seu dispositivo e permita notificações para Timer.Coffee.';

  @override
  String get notificationDebug => 'Depuração de notificações';

  @override
  String get testNotificationSystem => 'Testar sistema de notificações';

  @override
  String get notificationsEnabled => 'Ativadas';

  @override
  String get notificationsDisabled => 'Desativadas';

  @override
  String get notificationPermissionDialogTitle => 'Ativar Notificações?';

  @override
  String get notificationPermissionDialogMessage =>
      'Você pode ativar as notificações para receber atualizações úteis (ex. sobre novas versões do aplicativo). Ative agora ou altere isso a qualquer momento nas configurações.';

  @override
  String get notificationPermissionEnable => 'Ativar';

  @override
  String get notificationPermissionSkip => 'Agora não';

  @override
  String get holidayGiftBoxTitle => 'Caixa de Presentes de Férias';

  @override
  String get holidayGiftBoxInfoTrigger => 'O que é isso?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Ofertas sazonais selecionadas de parceiros. Links não são afiliados - nosso objetivo é apenas levar um pouco de alegria aos usuários do Timer.Coffee nestes feriados. Puxe para atualizar a qualquer momento.';

  @override
  String get holidayGiftBoxNoOffers => 'Nenhuma oferta disponível no momento.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Puxe para atualizar ou tente novamente mais tarde.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Mostrando ofertas para $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Ver detalhes';

  @override
  String get holidayGiftBoxPromoCopied => 'Código copiado';

  @override
  String get holidayGiftBoxPromoCode => 'Código promocional';

  @override
  String giftDiscountOff(String percent) {
    return 'Desconto de $percent%';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Até $percent% de desconto';
  }

  @override
  String get holidayGiftBoxTerms => 'Termos e condições';

  @override
  String get holidayGiftBoxVisitSite => 'Visitar site do parceiro';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Válido até $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Termina em $days dias',
      one: 'Termina amanhã',
      zero: 'Termina hoje',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable =>
      'Válido enquanto durar o estoque';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Atualizado em $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Idioma: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Tentar novamente';

  @override
  String get holidayGiftBoxLoadFailed => 'Falha ao carregar ofertas';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Oferta indisponível';

  @override
  String get holidayGiftBoxBannerTitle =>
      'Confira nossa caixa de presentes de feriado';

  @override
  String get holidayGiftBoxBannerCta => 'Ver ofertas';

  @override
  String get regionEurope => 'Europa';

  @override
  String get regionNorthAmerica => 'América do Norte';

  @override
  String get regionAsia => 'Ásia';

  @override
  String get regionAustralia => 'Austrália / Oceania';

  @override
  String get regionWorldwide => 'Mundo inteiro';

  @override
  String get regionAfrica => 'África';

  @override
  String get regionMiddleEast => 'Oriente Médio';

  @override
  String get regionSouthAmerica => 'América do Sul';

  @override
  String get setToZeroButton => 'Zerar';

  @override
  String get setToZeroDialogTitle => 'Zerar o estoque?';

  @override
  String get setToZeroDialogBody =>
      'Isto definirá a quantidade restante para 0 g. Você pode editá-la mais tarde.';

  @override
  String get setToZeroDialogConfirm => 'Zerar';

  @override
  String get setToZeroDialogCancel => 'Cancelar';

  @override
  String get inventorySetToZeroSuccess => 'Estoque definido para 0 g';

  @override
  String get inventorySetToZeroFail => 'Não foi possível zerar o estoque';
}
