// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class LPt extends L {
  LPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'Digite sua senha.';

  @override
  String get lockWrongPasscode => 'Isso não abriu o cofre.';

  @override
  String get lockCheckAndRetry => 'Confira a senha e tente de novo.';

  @override
  String get lockForgot => 'Esqueci minha senha';

  @override
  String get lockTypeTwelveWords => 'Digite suas doze palavras.';

  @override
  String get lockUsePasscodeInstead => 'Usar minha senha';

  @override
  String get lockUseFingerprint => 'Usar sua digital';

  @override
  String get lockFingerprintFailed => 'A digital não funcionou.';

  @override
  String get lockFingerprintUnavailable => 'A digital não está disponível.';

  @override
  String get lockOpening => 'Abrindo…';

  @override
  String get lockNothingDeleted => 'Nada foi apagado, e nada será.';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tente de novo em $count segundos.',
      one: 'Tente de novo em um segundo.',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tente de novo em $count minutos.',
      one: 'Tente de novo em um minuto.',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'HOJE';

  @override
  String get dayPrevious => 'O dia anterior';

  @override
  String get dayNext => 'O dia seguinte';

  @override
  String get daySearch => 'Buscar';

  @override
  String get daySettings => 'Ajustes';

  @override
  String get dayChooseDate => 'Escolher outra data.';

  @override
  String get dayEmptyToday => 'Alguma coisa que você queira guardar?';

  @override
  String get dayEmptyPast => 'Nada neste dia.';

  @override
  String get dayWriteSomething => 'Escrever algo para hoje';

  @override
  String get dayLineAsk => 'Como foi este dia?';

  @override
  String get dayLineHint => 'Como foi este dia?';

  @override
  String get dayLineSemantic => 'Diga em uma linha como foi este dia';

  @override
  String dayLineChange(String note) {
    return 'Este dia: $note. Mudar.';
  }

  @override
  String get dayEndOfDay => 'O fim do dia';

  @override
  String get dayStartOfDay => 'O começo do dia';

  @override
  String get firstPageTitle =>
      'Isto está vazio porque você ainda não escreveu nada aqui.';

  @override
  String get firstPageShelves =>
      'Os dias são as prateleiras. O que você guardar fica no dia em que aconteceu, e continua ali.';

  @override
  String get firstPageWayWrite => 'Toque nesta página para escrever.';

  @override
  String get firstPageWayVoice =>
      'Segure o microfone para falar em vez de escrever.';

  @override
  String get firstPageWayAttach =>
      'Adicione uma fotografia, um vídeo ou um documento.';

  @override
  String get firstPagePromise => 'Nada disso sai deste telefone.';

  @override
  String get firstPageSemantic => 'Escreva a primeira coisa no seu diário';

  @override
  String get captureVoice => 'Gravar uma nota de voz';

  @override
  String get capturePhoto => 'Tirar ou escolher uma foto';

  @override
  String get captureFile => 'Anexar um arquivo';

  @override
  String get backupNeverMade =>
      'Não há backup de nada disto. Se este aplicativo for removido, suas anotações vão junto.';

  @override
  String get backupStale => 'Já faz um tempo desde o último backup.';

  @override
  String get backupOutOfDate => 'Seu backup ainda abre com a senha antiga.';

  @override
  String get backupAction => 'Fazer backup';

  @override
  String folderAlsoIn(String name) {
    return 'Também em $name. Abrir a pasta.';
  }

  @override
  String get folderStaysHere =>
      'Continua onde está. Uma pasta é um segundo lugar para encontrar.';

  @override
  String get folderAddTo => 'Adicionar a uma pasta';

  @override
  String get folderNew => 'Nova pasta';

  @override
  String get folderNoneYet =>
      'Ainda não há pastas. Uma por pessoa, ou por fase — o que você sempre volta a olhar.';

  @override
  String folderLesson(String day, String folder) {
    return 'Continua em $day. Também em $folder.';
  }

  @override
  String get actionDone => 'Pronto';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Apagar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionUndo => 'Desfazer';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionRemove => 'Remover';

  @override
  String get actionNotNow => 'Agora não';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsSecurity => 'Bloqueio e segurança';

  @override
  String get settingsYourNotes => 'Suas anotações';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageNote =>
      'As palavras que o aplicativo usa. O que você escreve é seu, em qualquer idioma, seja qual for este ajuste.';

  @override
  String get settingsLanguageSystem => 'Seguir o telefone';

  @override
  String get entryMattered => 'Isto importou';

  @override
  String get entryMarked => 'Marcada como uma que importou.';

  @override
  String get entryMarkRemoved => 'Marca retirada.';

  @override
  String get entryDeleted => 'Excluído.';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versões anteriores',
      one: 'Uma versão anterior',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => 'Mantém as palavras';

  @override
  String entryKindInTrash(Object kind) {
    return 'O $kind está no lixo.';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return 'O $kind está no lixo. As palavras continuam aqui.';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count notas e todas as suas versões anteriores. Isto não se pode desfazer.',
      one: 'Uma nota e todas as suas versões anteriores. Isto não se pode desfazer.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => 'Nota vazia';

  @override
  String get kindPhoto => 'Foto';

  @override
  String get kindVideo => 'Vídeo';

  @override
  String get kindRecording => 'Gravação';

  @override
  String get kindFile => 'Ficheiro';

  @override
  String get entryNoLongerMarked => 'Não está mais marcado';

  @override
  String get entryFindAgain => 'Encontre de novo pela busca';

  @override
  String get searchGoTo => 'Ir para';

  @override
  String get searchFolders => 'Pastas';

  @override
  String get searchEntriesOne => '1 anotação';

  @override
  String searchEntriesMany(int count) {
    return '$count anotações';
  }

  @override
  String get searchNothingFound => 'Nada corresponde a isso.';

  @override
  String get searchEverythingInstead => 'Buscar em tudo';

  @override
  String get onboardNoAccount => 'Não existe conta.';

  @override
  String get onboardPromiseBody =>
      'Suas notas ficam neste telefone.\nNão temos servidor. Não podemos lê-las.\nTambém não podemos recuperá-las.';

  @override
  String get onboardBegin => 'Começar';

  @override
  String get onboardHaveBackup => 'Tenho um backup';

  @override
  String get onboardSetPasscode => 'Defina uma senha';

  @override
  String get onboardPasscodeBody =>
      'É a única coisa que abre suas notas. Uma frase de que você consiga lembrar é mais forte que quatro dígitos.';

  @override
  String get onboardPasscodeLabel => 'Senha';

  @override
  String get onboardPasscodeAgain => 'Digite de novo';

  @override
  String get onboardSettingUp => 'Preparando…';

  @override
  String get onboardContinue => 'Continuar';

  @override
  String get onboardPasscodesDiffer => 'Essas duas não coincidem.';

  @override
  String get onboardVaultFailed => 'Não foi possível criar seu cofre.';

  @override
  String get onboardVaultFailedThen => 'Nada foi salvo. Tente mais uma vez.';

  @override
  String get onboardWriteWords => 'Escreva estas doze palavras\nno papel';

  @override
  String get onboardWordsBody =>
      'Não temos uma cópia. Não podemos enviá-las para você. Não há nenhum e-mail de suporte que possa ajudar.\n\nNo papel, não uma captura de tela. Uma captura fica na sua galeria, que é o primeiro lugar onde qualquer um olha.';

  @override
  String get onboardWrittenDown => 'Já anotei';

  @override
  String get onboardCopyWords => 'Copiar as doze palavras';

  @override
  String get onboardClipboardNote =>
      'A área de transferência se limpa sozinha depois de um minuto. Até lá, outros aplicativos podem lê-la.';

  @override
  String get onboardCopied =>
      'Copiado. Se limpa sozinho em um minuto — cole agora em um lugar seguro.';

  @override
  String get onboardCopyFailed =>
      'Não foi possível copiar. Escrever à mão é mais seguro de qualquer forma.';

  @override
  String get onboardCheckThree => 'Confira três delas';

  @override
  String get onboardCheckBody =>
      'Assim sabemos que o papel está certo, não a tela.';

  @override
  String onboardWordNumber(int number) {
    return 'Palavra $number';
  }

  @override
  String onboardWordWrong(int number) {
    return 'A palavra $number não está certa. Veja o que você anotou.';
  }

  @override
  String get onboardShowWords => 'Mostre as palavras de novo';

  @override
  String get onboardFingerprintTitle => 'Abrir com sua digital?';

  @override
  String get onboardFingerprintBody =>
      'Assim você não precisa digitar aquela frase toda vez.';

  @override
  String get onboardFingerprintExplain =>
      'Sua frase continua sendo a chave. A digital abre apenas este cofre, apenas neste telefone, e o Android a desliga sozinho se as digitais do telefone mudarem — para que ninguém possa adicionar a sua e entrar. Ela nunca faz parte de um backup.';

  @override
  String get onboardFingerprintWaiting => 'Esperando seu dedo…';

  @override
  String get onboardFingerprintUse => 'Usar minha digital';

  @override
  String get onboardFingerprintFailed => 'Isso não funcionou.';

  @override
  String get onboardOneLastThing => 'Uma última coisa';

  @override
  String get onboardNameBody =>
      'Como o Lamplight deve chamar você? Fica neste telefone, e você pode mudar ou deixar em branco.';

  @override
  String get onboardFingerprintOn =>
      'Sua digital vai abrir o Lamplight de agora em diante.';

  @override
  String get onboardYourName => 'Seu nome';

  @override
  String get onboardStartWriting => 'Começar a escrever';

  @override
  String get onboardSkip => 'Pular';

  @override
  String get settingsGroupLook => 'Como ele aparece e fala';

  @override
  String get settingsGroupWhoCanOpen => 'Quem pode abrir';

  @override
  String get settingsGroupKeeping => 'Guardar, e levar junto';

  @override
  String get settingsAppearanceNote => 'Tema, fonte, cor, página';

  @override
  String get settingsFolders => 'Pastas';

  @override
  String get settingsFoldersNote => 'Pessoas, lugares, fases';

  @override
  String get settingsMedia => 'Multimédia';

  @override
  String get settingsMediaNote => 'Fotos, vídeo, som e documentos';

  @override
  String get mediaGroupDocuments => 'Documentos';

  @override
  String get mediaDocumentsKept => 'Guardados exatamente como chegaram';

  @override
  String get mediaDocumentsFooter =>
      'Um PDF ou um ficheiro Word já vem comprimido por dentro, por isso comprimi-lo outra vez poupa cerca de cinco por cento. Para fazer diferença seria preciso voltar a codificar as imagens lá dentro, o que desfoca para sempre as letras pequenas de uma digitalização — e só daria por isso anos depois, no dia em que precisasse de o ler.';

  @override
  String get settingsTrash => 'Lixeira';

  @override
  String get settingsTrashNote => 'Entradas apagadas, guardadas por 30 dias';

  @override
  String get settingsReadableCopy => 'Cópia legível';

  @override
  String get settingsReadableCopyNote =>
      'Markdown e seus arquivos, numa pasta que você escolher';

  @override
  String get settingsBringIn => 'Trazer um diário antigo';

  @override
  String get settingsBringInNote =>
      'Arquivos de texto de outro aplicativo, organizados pela data no nome';

  @override
  String get settingsKeepingFooter =>
      'Um backup fica trancado com sua senha, igual ao cofre. Uma cópia legível não fica trancada de jeito nenhum — são arquivos comuns numa pasta que você escolhe.';

  @override
  String get backupNever => 'Nunca teve backup';

  @override
  String get backupToday => 'Backup feito hoje';

  @override
  String get backupYesterday => 'Backup feito ontem';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Backup feito há $count dias',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => 'Na entrada';

  @override
  String get mediaGroupVoice => 'Notas de voz';

  @override
  String get mediaIncomingFooter =>
      'O Lamplight nunca guarda uma segunda cópia menor — o que você escolher aqui é o que fica guardado, e o original não fica em nenhum outro lugar.';

  @override
  String get mediaVoiceFooter =>
      'A transcrição acontece neste telefone, pelo reconhecedor que o Android já tem. Nada do que você fala no Lamplight é enviado para lugar nenhum, e o aplicativo não tem permissão para enviar.';

  @override
  String get mediaPhotoSize => 'Tamanho das fotos';

  @override
  String get mediaVideoSize => 'Tamanho dos vídeos';

  @override
  String get mediaAskEachTime => 'Perguntar toda vez';

  @override
  String get accentAmber => 'Âmbar';

  @override
  String get accentAmberNote => 'Um abajur à noite. O de sempre.';

  @override
  String get accentRose => 'Rosa';

  @override
  String get accentRoseNote => 'Rosa quente. Mais suave que o âmbar.';

  @override
  String get accentSage => 'Sálvia';

  @override
  String get accentSageNote => 'Verde tranquilo. O mais calmo dos seis.';

  @override
  String get accentSlate => 'Ardósia';

  @override
  String get accentSlateNote => 'Cinza-azulado frio. O mais neutro.';

  @override
  String get accentPlum => 'Ameixa';

  @override
  String get accentPlumNote => 'Roxo profundo.';

  @override
  String get accentEmber => 'Brasa';

  @override
  String get accentEmberNote => 'Laranja queimado. O mais quente.';

  @override
  String get surfacePlain => 'Lisa';

  @override
  String get surfacePlainNote => 'Uma página sem nada.';

  @override
  String get surfacePaper => 'Papel';

  @override
  String get surfacePaperNote =>
      'Um grão leve, para a página parecer material. A de sempre.';

  @override
  String get surfaceLamplit => 'Sob a luz';

  @override
  String get surfaceLamplitNote => 'Papel, com o abajur aceso.';

  @override
  String get surfaceStarMap => 'Mapa do céu';

  @override
  String get surfaceStarMapNote =>
      'Um só céu, girando com o relógio. Nunca igual duas vezes no mesmo dia.';

  @override
  String get rulingNone => 'Nada';

  @override
  String get rulingNoneNote => 'Nada impresso na página.';

  @override
  String get rulingLines => 'Linhas';

  @override
  String get rulingLinesNote => 'Pautada como um caderno.';

  @override
  String get rulingIsometric => 'Isométrica';

  @override
  String get rulingIsometricNote =>
      'Papel de desenho técnico, para pensar em três dimensões.';

  @override
  String get rulingTriangle => 'Triângulos';

  @override
  String get rulingTriangleNote => 'Um campo de triângulos equiláteros.';

  @override
  String get rulingDots => 'Grade de pontos';

  @override
  String get rulingDotsNote =>
      'Um ponto em cada cruzamento. A mais discreta das quatro.';

  @override
  String get faceSystem => 'Do sistema';

  @override
  String get faceSystemNote => 'A que o resto do seu telefone usa.';

  @override
  String get faceSerif => 'Serifada do sistema';

  @override
  String get faceSerifNote => 'A serifada do próprio telefone.';

  @override
  String get faceCalmNote => 'Bordas macias, letras largas.';

  @override
  String get faceModernNote => 'Justa e atual.';

  @override
  String get faceOldStyleNote => 'Uma letra de livro do século XVI.';

  @override
  String get facePlayfulNote => 'Redonda e alegre.';

  @override
  String get faceChildlikeNote => 'Um caderno de escola.';

  @override
  String get faceHandwrittenNote =>
      'Letra de mão, e ainda assim legível numa página inteira.';

  @override
  String get faceMedievalNote => 'A mão de um copista. Uma espessura só.';

  @override
  String get faceMonoNote => 'Todas as letras da mesma largura.';

  @override
  String get qualityOriginal => 'Manter o original';

  @override
  String get qualityBalanced => 'Equilibrado';

  @override
  String get qualitySmaller => 'Menor';

  @override
  String get photoOriginalNote =>
      'Guardada exatamente como sua câmera fez. Os arquivos maiores — e eles guardam o lugar onde a foto foi tirada, que o Lamplight normalmente remove.';

  @override
  String get photoBalancedNote =>
      'Bem menor, e difícil de distinguir do original. O de sempre.';

  @override
  String get photoSmallerNote =>
      'Metade outra vez. Você pode notar se ampliar bastante.';

  @override
  String get videoOriginalNote =>
      'Guardado exatamente como sua câmera gravou. De longe, os arquivos maiores.';

  @override
  String get videoBalancedNote =>
      'Bem menor, e difícil de distinguir do original. O de sempre.';

  @override
  String get videoSmallerNote =>
      'Metade outra vez. Você pode notar numa tela grande.';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceThemeDark => 'Escuro';

  @override
  String get appearanceThemeLight => 'Claro';

  @override
  String get appearanceThemeAuto => 'Auto';

  @override
  String get appearanceThemeAutoNote =>
      'Segue o ajuste de claro e escuro do seu telefone.';

  @override
  String get appearanceFont => 'Fonte';

  @override
  String get appearanceSize => 'Tamanho';

  @override
  String get appearanceColour => 'Cor';

  @override
  String get appearancePage => 'Página';

  @override
  String get appearanceRuling => 'Pauta';

  @override
  String get daySavedToToday => 'Guardado em hoje.';

  @override
  String get dayAddedToToday => 'Adicionado a hoje.';

  @override
  String get entryEditWords => 'Editar as palavras';

  @override
  String get entryDeleteBlock => 'Apagar o bloco inteiro';

  @override
  String entrySavedAs(String name) {
    return 'Salvo como $name.';
  }

  @override
  String entryAddedToFolder(String name) {
    return 'Também em $name.';
  }

  @override
  String get entrySaveCopy => 'Salvar uma cópia';

  @override
  String get entrySaveCopyNote => 'Onde você escolher, fora do Lamplight';

  @override
  String get capturePhotoTake => 'Tirar uma foto';

  @override
  String get capturePhotoChoose => 'Escolher das suas fotos';

  @override
  String get composerHintToday => 'Escreva sobre hoje…';

  @override
  String get composerHintPast => 'Escreva sobre este dia…';

  @override
  String get composerNewBlock => 'Novo bloco';

  @override
  String get voiceShowTranscript => 'Mostrar o que foi dito';

  @override
  String get voiceHideTranscript => 'Ocultar o que foi dito';

  @override
  String get voiceTranscriptTitle => 'O que foi dito';

  @override
  String get entryEdited => ', editado';

  @override
  String photoSemantic(String time) {
    return 'Foto das $time. Toque duas vezes para ver.';
  }

  @override
  String get sizeThisPhoto => 'esta foto';

  @override
  String get sizeThesePhotos => 'estas fotos';

  @override
  String get sizeThisVideo => 'este vídeo';

  @override
  String get sizeTheseVideos => 'estes vídeos';

  @override
  String sizeQuestion(String what) {
    return 'De que tamanho guardar $what?';
  }

  @override
  String get trashNote =>
      'O que é apagado fica aqui por 30 dias e depois vai de vez.';

  @override
  String get trashConfirm => 'Apagar isto de vez?';

  @override
  String get trashKeep => 'Ficar com eles';

  @override
  String get trashDeleteForGood => 'Apagar de vez';

  @override
  String get trashPutBack => 'Devolver';

  @override
  String trashPutBackOn(String day) {
    return 'Devolvido ao dia $day.';
  }

  @override
  String get trashEmpty => 'Esvaziar a lixeira';

  @override
  String get folderMakeFirst => 'Criar a primeira';

  @override
  String folderDeleteAsk(String name) {
    return 'Apagar “$name”?';
  }

  @override
  String get folderKeepIt => 'Ficar com ela';

  @override
  String get folderDeleteIt => 'Apagar a pasta';

  @override
  String get folderRename => 'Renomear';

  @override
  String get folderDeleteThis => 'Apagar esta pasta';

  @override
  String folderTakenOut(String name) {
    return 'Tirado de $name. Continua no dia dele.';
  }

  @override
  String get searchHint => 'Palavras, uma data, um nome…';

  @override
  String get searchBack => 'Voltar';

  @override
  String get searchClear => 'Limpar';

  @override
  String searchNothingMatches(String query) {
    return 'Nada corresponde a “$query”.';
  }

  @override
  String get searchWhatMattered => 'O QUE IMPORTOU';

  @override
  String get searchADate => 'Uma data';

  @override
  String get searchDateExample => '16 março 2006 · março 2006 · ontem';

  @override
  String get searchWhatYouCanType => 'O que pode procurar';

  @override
  String get searchTryDate => 'ontem';

  @override
  String get searchSaidOutLoud => 'dito em voz alta';

  @override
  String get searchAPhotograph => 'Uma foto';

  @override
  String get searchAVideo => 'Um vídeo';

  @override
  String get securityWhileOpen => 'Enquanto o app está aberto';

  @override
  String get securityLockFooter =>
      'O Lamplight sempre tranca assim que vai para segundo plano. Isto decide só quanto tempo ele espera enquanto você ainda está dentro.';

  @override
  String get securityLockAfter => 'Trancar depois de';

  @override
  String get securityOneHour => '1 hora';

  @override
  String get securityYourPasscode => 'Sua senha';

  @override
  String get securityPasscodeFooter =>
      'Sua senha é a chave. Ela não fica guardada em lugar nenhum — nem neste telefone nem em outro lugar — então ninguém pode ser obrigado a entregá-la, e ninguém pode recuperá-la para você.';

  @override
  String get securityChangePasscode => 'Mudar a senha';

  @override
  String get securityScreenshots => 'Capturas de tela';

  @override
  String get securityScreenshotsFooter =>
      'O Lamplight bloqueia capturas de tela para que quem pegar seu telefone não consiga fotografar suas notas, e para que elas nunca apareçam na prévia dos apps recentes. Você pode desligar isso no seu próprio telefone.';

  @override
  String get securityAllowScreenshots => 'Permitir capturas de tela';

  @override
  String get securityScreenshotsOn =>
      'As suas notas vão aparecer nas apps recentes';

  @override
  String get securityScreenshotsOff =>
      'As apps recentes mostram uma página em branco';

  @override
  String get securityCouldNotChange => 'Não foi possível alterar isso.';

  @override
  String get securityNothingChanged => 'Nada mudou no seu bloqueio.';

  @override
  String get securityPromptAutomatic => 'O pedido aparece sozinho';

  @override
  String get securityPromptOnTap => 'Toque na impressão digital quando quiser';

  @override
  String get mediaAskEachTimeOn =>
      'É-lhe perguntado que tamanho guardar para fotos e vídeos ao adicioná-los.';

  @override
  String get mediaAskEachTimeOff =>
      'Desligado. São usados os dois tamanhos acima, sem perguntar.';

  @override
  String get passcodeNew => 'Novo código';

  @override
  String get securityFingerprint => 'Digital';

  @override
  String get securityFingerprintFooter =>
      'Sua frase continua sendo a chave. A digital abre apenas este cofre, apenas neste telefone, e o Android a desliga sozinho se as digitais do telefone mudarem — para que ninguém possa adicionar a sua e entrar. Ela nunca faz parte de um backup.';

  @override
  String get securityUnlockWithFingerprint => 'Abrir com minha digital';

  @override
  String get securityAskOnOpen => 'Perguntar assim que o Lamplight abrir';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => 'Nunca';

  @override
  String get securityDefaultNote => 'O de sempre.';

  @override
  String get securityHourNote => 'Para uma tarde relendo.';

  @override
  String get securityNeverNote =>
      'Ele tranca do mesmo jeito assim que você sai do app.';

  @override
  String get calendarGoToDate => 'Ir para uma data';

  @override
  String get dayHasWriting => 'escrita';

  @override
  String get dayHasPhoto => 'uma foto';

  @override
  String get dayHasVideo => 'um vídeo';

  @override
  String get dayHasVoice => 'uma nota de voz';

  @override
  String get dayHasFile => 'um ficheiro';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count, $kinds';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listAnd(Object last, Object most) {
    return '$most e $last';
  }

  @override
  String get integrityNothingUnusual =>
      'Nada de estranho neste telemóvel. O Lamplight está a funcionar como deve.';

  @override
  String get calendarPreviousYear => 'Ano anterior';

  @override
  String get calendarPreviousMonth => 'Mês anterior';

  @override
  String get calendarNextYear => 'Ano seguinte';

  @override
  String get calendarNextMonth => 'Mês seguinte';

  @override
  String get calendarBackToMonth => 'Voltar ao mês';

  @override
  String get calendarWholeYear => 'O ano inteiro';

  @override
  String get calendarBackToThisMonth => 'Voltar a este mês';

  @override
  String get calendarNothingThisYear => 'Ainda não há nada neste ano.';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$entries em $days.';
  }

  @override
  String get folderNothingInIt => 'Ainda sem nada';

  @override
  String get onThisDayOneYear => 'Hoje há um ano';

  @override
  String onThisDayYears(Object years) {
    return 'Hoje há $years anos';
  }

  @override
  String wheelYear(Object year) {
    return 'Ano $year';
  }

  @override
  String get calendarBackToBrowsing => 'Voltar a folhear';

  @override
  String get calendarToday => 'Hoje';

  @override
  String get calendarFirstEntry => 'Sua primeira anotação';

  @override
  String get calendarGoToThisDay => 'Ir para este dia';

  @override
  String get calendarDensityNote =>
      'A cor mostra quanto tem num dia, de nada a muito.';

  @override
  String get calendarLess => 'Menos';

  @override
  String get calendarMore => 'Mais';

  @override
  String get calendarGoToToday => 'Ir para hoje';

  @override
  String get backupTitle => 'Backup';

  @override
  String get vaultNothingToBackUp =>
      'Ainda não há nada neste cofre para copiar.';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return 'Algo mudou enquanto a cópia era feita ($name). Tente outra vez.';
  }

  @override
  String get vaultTooSmall =>
      'Este ficheiro é demasiado pequeno para ser uma cópia do Lamplight.';

  @override
  String get vaultNotALamplightFile =>
      'Este não é um ficheiro de cópia do Lamplight.';

  @override
  String get vaultDamaged =>
      'Este ficheiro está danificado e não pode ser aberto.';

  @override
  String get vaultKeyringNewerVersion =>
      'Este cofre foi feito com uma versão mais recente do Lamplight. Atualize a aplicação para o abrir.';

  @override
  String get vaultKeyringDamaged =>
      'O ficheiro da chave do cofre está danificado e não pode ser lido. Se tiver uma cópia, reponha a partir dela.';

  @override
  String get vaultDatabaseNewerVersion =>
      'Este cofre foi feito com uma versão mais recente do Lamplight. Atualize a aplicação para o abrir — as suas notas estão intactas e nada foi alterado.';

  @override
  String phraseWrongLength(Object count) {
    return 'Uma frase de recuperação tem 12 palavras. Esta tem $count.';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '\"$word\" não é uma das palavras de recuperação.';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'Essas palavras não são uma frase de recuperação válida. Veja se há uma mal escrita ou trocada.';

  @override
  String get vaultNewerVersion =>
      'Esta cópia foi feita com uma versão mais recente do Lamplight. Atualize a aplicação e tente outra vez.';

  @override
  String get vaultUnknownCompression =>
      'Esta cópia usa uma compressão que esta versão não sabe ler.';

  @override
  String get vaultDamagedTryOlder =>
      'Este ficheiro está danificado e não pode ser aberto. Se tiver uma cópia mais antiga, tente essa.';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'Esta cópia foi feita antes de as frases de recuperação poderem abrir cópias. O código dela é a única forma de entrar.';

  @override
  String get vaultWordsDoNotOpenIt =>
      'Essas palavras não abrem este ficheiro. Podem ser de outro cofre.';

  @override
  String get vaultWrongPasscode => 'Esse código não abre este ficheiro.';

  @override
  String vaultMissingPart(Object name) {
    return 'A esta cópia falta uma parte de si mesma ($name).';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'Esta cópia está danificada ($name tem o tamanho errado).';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'Esta cópia está danificada ($name não corresponde).';
  }

  @override
  String get vaultNoVaultInside =>
      'Esta cópia não contém um cofre. Pode ter sido feita por outra aplicação.';

  @override
  String get vaultOutOfOrder =>
      'Este ficheiro está danificado: o conteúdo está fora de ordem.';

  @override
  String get vaultEndsPartWay => 'Este ficheiro está danificado: acaba a meio.';

  @override
  String vaultIncomplete(Object parts) {
    return 'Este ficheiro está incompleto — tem $parts das suas partes.';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'Esta cópia contém algo que o Lamplight não vai abrir ($name).';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => 'A verificar se abre…';

  @override
  String get backupCouldNotSave => 'Não foi possível guardar a cópia.';

  @override
  String get backupNothingLost =>
      'Nada se perdeu e as suas notas estão intactas. Tente outra vez daqui a pouco.';

  @override
  String get backupLast => 'Última cópia';

  @override
  String get backupInTheVault => 'No cofre';

  @override
  String get restoreCheckingFile => 'A verificar o ficheiro…';

  @override
  String get restoreCouldNotOpen => 'Não foi possível abrir esse ficheiro.';

  @override
  String get restoreCheckItIsTheOne =>
      'Verifique se é a cópia que queria e tente outra vez.';

  @override
  String get restorePuttingInPlace => 'A colocar no lugar…';

  @override
  String get restorePuttingBack => 'A repor as suas notas antigas…';

  @override
  String get restoreCouldNotFinish => 'Não foi possível concluir a reposição.';

  @override
  String get restoreBackAsTheyWere => 'As suas notas estão como estavam.';

  @override
  String get restoreUsePasscodeInstead => 'Usar antes o código';

  @override
  String get restoreUseWordsInstead => 'Tenho antes as doze palavras';

  @override
  String get backupCreateFile => 'Criar o arquivo';

  @override
  String get backupCreatedChecked => 'Backup criado e conferido.';

  @override
  String get backupMakeAnother => 'Fazer outro';

  @override
  String get backupRestoreHeading => 'Restaurar';

  @override
  String get backupRestoreFrom => 'Restaurar de um arquivo';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent por cento';
  }

  @override
  String get restoreTitle => 'Restaurar';

  @override
  String get restoreChooseFile => 'Escolher um arquivo';

  @override
  String get restorePhraseHint => 'lembra história indústria…';

  @override
  String get restoreAction => 'Restaurar';

  @override
  String get restoreChooseDifferent => 'Escolher outro arquivo';

  @override
  String get importChooseFolder => 'Escolher uma pasta';

  @override
  String get importChooseFiles => 'Escolher os arquivos';

  @override
  String get importChooseFilesNote =>
      'Se o Android recusar sua pasta — ele não dá a nenhum app a pasta Downloads nem a raiz do armazenamento — escolha os arquivos diretamente. Isso nunca é recusado.';

  @override
  String get importLooking => 'Olhando dentro da pasta…';

  @override
  String get importNoTextFiles => 'Não há arquivos de texto nessa pasta.';

  @override
  String get importChooseDifferentFolder => 'Escolher outra pasta';

  @override
  String get importUseFileDate => 'Usar a data do próprio arquivo';

  @override
  String get importUseFileDateNote =>
      'Coloca no dia em que o arquivo foi alterado pela última vez. Muitas vezes não é o dia sobre o qual ele fala.';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trazer $count notas',
      one: 'Trazer 1 nota',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return 'Trazendo, $percent por cento';
  }

  @override
  String get exportChooseFolder => 'Escolher uma pasta e exportar';

  @override
  String get exportWritten => 'Sua cópia está escrita.';

  @override
  String get exportAgain => 'Exportar de novo';

  @override
  String get exportWhichOne => 'Qual eu quero?';

  @override
  String get exportNotLocked => 'Esta cópia não está trancada';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coisas adicionadas a hoje.',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'Escrever uma nota sobre isto';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adicionados.',
      one: 'Adicionado.',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => 'Não foi possível ler essa pasta.';

  @override
  String get importNothingBrought => 'Não foi trazido nada.';

  @override
  String get importStoppedPartWay => 'A importação do diário parou a meio.';

  @override
  String get importWhatArrivedKept =>
      'Tudo o que chegou antes de parar foi guardado.';

  @override
  String get importNoReadableDates =>
      'Nenhum desses ficheiros tem uma data que o Lamplight saiba ler.';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas prontas para trazer.',
      one: '1 nota pronta para trazer.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => 'Não há nada de novo para trazer.';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas trazidas.',
      one: '1 nota trazida.',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count já cá estavam, por isso ficaram como estavam.';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count não tinham data legível e foram ignoradas.';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count não puderam ser lidas: $names';
  }

  @override
  String get exportStarting => 'A começar…';

  @override
  String get exportCouldNotFinish =>
      'Não foi possível concluir a cópia legível.';

  @override
  String get exportNothingChanged => 'Nada mudou dentro do Lamplight.';

  @override
  String get importVideoAlreadySmall =>
      'Um vídeo já era o mais pequeno possível, por isso foi guardado tal como está.';

  @override
  String get importVideoCouldNotShrink =>
      'Um vídeo não pôde ser reduzido neste telemóvel, por isso foi guardado inteiro.';

  @override
  String importOneFailed(String reason) {
    return 'Um não deu certo: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count não terminaram antes de o Lamplight trancar.',
      one: 'Um não terminou antes de o Lamplight trancar.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => 'Nada ficou no telefone.';

  @override
  String get nameCardAsk => 'O que deve estar escrito aqui?';

  @override
  String get nameCardHint => 'Seu nome, ou o que quiser';

  @override
  String get reminderGroup => 'Um empurrãozinho, se você quiser';

  @override
  String get reminderFooter =>
      'Desligado até você ligar. Nunca menciona o que há nas suas notas — não pode, porque roda com o cofre trancado. Sem sequências, sem contagens, nada sobre os dias que você pulou.';

  @override
  String get reminderTitle => 'Me lembrar de escrever';

  @override
  String get reminderWhen => 'Quando';

  @override
  String get reminderProblemNotAllowed =>
      'O Lamplight não tem permissão para enviar notificações.';

  @override
  String get reminderProblemNotificationsOff =>
      'As definições deste telemóvel têm as notificações do Lamplight desligadas.';

  @override
  String get reminderProblemRemindersOff =>
      'Os lembretes do Lamplight estão desligados nas definições de notificações deste telemóvel.';

  @override
  String get reminderProblemBatterySaving =>
      'Este telemóvel está a poupar bateria travando o Lamplight. É essa a razão habitual para um lembrete chegar tarde ou nunca chegar.';

  @override
  String get reminderMayNotArrive => 'O lembrete pode não chegar';

  @override
  String get backupAutomatic => 'Fazer backup sozinho';

  @override
  String get backupAutomaticDidNotFinish => 'A cópia automática não terminou.';

  @override
  String get backupNothingYet => 'Ainda não há nada para copiar.';

  @override
  String get backupInProgress => 'A fazer cópia…';

  @override
  String get backupStartsAtUnlock => 'Começa no próximo desbloqueio.';

  @override
  String get backupDoneAutomatically => 'Cópia feita automaticamente.';

  @override
  String get backupLastOneFailed =>
      'A última cópia automática não terminou. Vai tentar outra vez na próxima vez que abrir o Lamplight.';

  @override
  String importNthOf(Object index, Object total) {
    return '$index de $total';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count à espera',
      one: '1 à espera',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'Copiado';

  @override
  String get failureGeneric => 'Isso não funcionou.';

  @override
  String get failureNothingLost => 'Nada se perdeu — tente outra vez.';

  @override
  String get calendarNothingOnDay => 'nada';

  @override
  String get backupChangeFolder => 'Trocar a pasta';

  @override
  String backupSavedTo(String place) {
    return 'Guardado em $place';
  }

  @override
  String get backupUseDefaultFolder => 'Usar a pasta habitual';

  @override
  String get backupChooseFolder => 'Escolha uma pasta para guardar as cópias';

  @override
  String get folderAndroidRestriction =>
      'O Android não deixa nenhuma aplicação ficar com a pasta Transferências nem com todo o armazenamento interno. Documentos, ou uma pasta lá dentro, resulta.';

  @override
  String get folderNotWritable =>
      'Não é possível guardar nada nessa pasta. Tente outra.';

  @override
  String get folderRefused => 'Não foi possível usar essa pasta.';

  @override
  String get folderTryAnother => 'Tente escolher outra.';

  @override
  String get aboutHowKept => 'Como suas notas são guardadas';

  @override
  String get aboutFonts => 'Fontes e licenças';

  @override
  String get aboutVersion => 'Versão';

  @override
  String get aboutNoBrowser =>
      'Nenhum app deste telefone consegue abrir links.';

  @override
  String get aboutMadeBy => 'Feito por';

  @override
  String get aboutMadeBySemantic =>
      'Feito por ProbablyPiyush. Abre o LinkedIn no seu navegador.';

  @override
  String get aboutCoffee => 'Me paga um café';

  @override
  String get aboutCoffeeSemantic =>
      'Me paga um café. Abre uma página no seu navegador.';

  @override
  String get aboutCopyDetails => 'Copiar os detalhes';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. Toque para alterar.';
  }

  @override
  String get settingsAddName => 'Ponha o seu nome';

  @override
  String get settingsNameOnlyHere => 'Só neste telemóvel';

  @override
  String get settingsNameOptional => 'Opcional. Nunca sai deste telemóvel.';

  @override
  String get reminderTurnedOffByAndroid =>
      'O Android tem as notificações desligadas para o Lamplight. Pode ligá-las nas definições do telemóvel, em Aplicações.';

  @override
  String get reminderOnceADay => 'Uma vez por dia';

  @override
  String reminderTodayAt(Object time) {
    return 'hoje às $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'ontem às $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return 'a $date às $time';
  }

  @override
  String get reminderNoneYet => 'Ainda não chegou nada';

  @override
  String reminderLastArrived(Object when) {
    return 'A última chegou $when';
  }

  @override
  String reminderNextDue(Object when) {
    return 'A próxima está prevista para $when';
  }

  @override
  String get aboutHide => 'Ocultar';

  @override
  String get aboutCheckReal => 'Verificar que este é o Lamplight verdadeiro';

  @override
  String get entryRevisionsNote => 'O que dizia antes de você mudar';

  @override
  String get entryStaysOnDay => 'Continua neste dia também';

  @override
  String entryDeleteKind(String kind) {
    return 'Apagar $kind';
  }

  @override
  String get shareCouldNotAdd =>
      'Não deu para adicionar. Tente salvar e usar o botão de foto.';

  @override
  String get openNothingCanOpen =>
      'Nada neste telefone consegue abrir esse tipo de arquivo.';

  @override
  String get viewerMore => 'Mais';

  @override
  String get docLeavesLamplight => 'Isto sai do Lamplight';

  @override
  String get docKeepItHere => 'Deixar aqui';

  @override
  String get docOpenWith => 'Abrir com…';

  @override
  String docCannotShow(String kind) {
    return 'O Lamplight mostra PDFs, imagens e texto sem nunca deixá-los abertos no seu telefone. Um arquivo $kind precisa de outro aplicativo — o Lamplight pode emprestá-lo enquanto você lê e pegar de volta depois.';
  }

  @override
  String get menuOpenWithNote => 'Outro aplicativo, sem deixar cópia';

  @override
  String menuSaveKind(String kind) {
    return 'Salvar $kind';
  }

  @override
  String get menuTrashNote => 'Guardado por 30 dias, depois some';

  @override
  String get videoBackTen => 'Dez segundos atrás';

  @override
  String get videoForwardTen => 'Dez segundos à frente';

  @override
  String get photoPlayVideo => 'Tocar este vídeo';

  @override
  String get lockPhraseHint => 'Suas doze palavras, com espaços';

  @override
  String get lockUnlock => 'Abrir';

  @override
  String get errorScreenDidNotOpen => 'Essa tela não abriu. Nada foi perdido.';

  @override
  String get errorGoBack => 'Voltar';

  @override
  String recordingCannot(String what) {
    return 'Este telefone não vai $what uma gravação. Ainda está gravando.';
  }

  @override
  String get recordingClose => 'Fechar';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gravando, $count segundos',
      one: 'Gravando, $count segundo',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => 'Parar e ficar com esta gravação';

  @override
  String get recordingDiscard => 'Descartar';

  @override
  String get recordingCouldNotStart => 'Não foi possível começar a gravar.';

  @override
  String get recordingCheckMicrophone =>
      'Verifique se o Lamplight tem permissão para usar o microfone.';

  @override
  String get recordingStartAgain => 'recomeçar';

  @override
  String get recordingCouldNotSave => 'Não foi possível guardar essa gravação.';

  @override
  String get recordingStillHere => 'Continua aqui — tente parar outra vez.';

  @override
  String get recordingCarryOnSemantic => 'Continuar a gravar';

  @override
  String get recordingPauseSemantic => 'Pausar esta gravação';

  @override
  String get recordingCarryOn => 'Continuar';

  @override
  String get recordingPause => 'Pausar';

  @override
  String get sizeAdd => 'Adicionar';

  @override
  String get transcribeTitle => 'Escrever o que for dito';

  @override
  String get transcribeOn =>
      'As notas de voz ficam pesquisáveis. Nada é enviado para lugar nenhum.';

  @override
  String get transcribeOff =>
      'Desligado. As notas de voz só são encontradas pelo dia delas.';

  @override
  String get transcribeLanguage => 'Idioma falado';

  @override
  String get transcribeLanguageNote =>
      'O idioma em que você fala nas suas gravações. Um de cada vez — uma frase que troca de idioma volta como a metade que combina com este.';

  @override
  String get transcribeNotDownloaded =>
      'Ainda não baixado neste telefone — toque para pegar.';

  @override
  String transcribeGetBetter(String name) {
    return 'Pegar o modelo melhor de $name';
  }

  @override
  String get transcribeGetBetterNote =>
      'As transcrições ficam bem mais precisas com ele. O download é do seu telefone, não do Lamplight, e acontece uma vez só.';

  @override
  String get transcribeNoLanguages =>
      'Este telefone ainda não ofereceu nenhum idioma.';

  @override
  String get transcribeNeedsDownloading => 'Precisa baixar';

  @override
  String folderStill(String day, String folder) {
    return 'Continua em $day. Também em $folder.';
  }

  @override
  String get folderRenameTitle => 'Renomear a pasta';

  @override
  String get folderNameHint => 'Uma pessoa, um lugar, uma fase';

  @override
  String get voicePlay => 'Ouvir esta nota de voz';

  @override
  String get voiceForwardThirty => 'Trinta segundos à frente';

  @override
  String voiceSpeed(String speed) {
    return 'Velocidade, agora $speed vezes';
  }

  @override
  String get voiceLengthUnknown =>
      'nota de voz, duração desconhecida até tocar';

  @override
  String get voicePosition => 'Posição na gravação';

  @override
  String get voiceOpening => 'Abrindo a gravação';

  @override
  String get voiceNoWords => 'Não voltou nenhuma palavra — tente de novo';

  @override
  String get voiceWriteThis => 'Escrever isto';

  @override
  String get voiceCannotWrite =>
      'Este telefone não consegue escrever notas de voz.';

  @override
  String get voiceLanguageMissing =>
      'Este telefone ainda não baixou esse idioma.';

  @override
  String get voiceWriting => 'Escrevendo…';

  @override
  String get voiceWaiting => 'Esperando para ser escrito.';

  @override
  String get voiceWritten => 'Escrito neste telefone.';

  @override
  String get errorPartNotShown => 'Esta parte não pôde ser mostrada.';

  @override
  String get errorScreenShort => 'Essa tela não abriu.';

  @override
  String get errorNothingLost =>
      'Nada foi perdido. Tudo o que você escreveu continua no cofre, exatamente como estava.';

  @override
  String get errorHideDetails => 'Ocultar os detalhes técnicos';

  @override
  String get errorShowDetails => 'Ver os detalhes técnicos';

  @override
  String get errorDetailsNote =>
      'Isto é tudo o que seria copiado. Diz o que quebrou e em que ponto do código — não contém nada do que você escreveu.';

  @override
  String get passcodeChangeFailed => 'Não deu para mudar a senha.';

  @override
  String get passcodeOldStillWorks => 'Sua senha antiga continua valendo.';

  @override
  String get passcodeChanged => 'Senha alterada';

  @override
  String get passcodeWordsUnchanged =>
      'Suas doze palavras não mudaram, e você não precisa de novas. Elas abrem seu cofre e seus backups exatamente como antes.';

  @override
  String get passcodeOldBackups =>
      'Os backups que você já tem continuam abrindo com a senha antiga. Um novo, feito agora, vai usar a nova.';

  @override
  String get passcodeMakeBackup => 'Fazer um backup agora';

  @override
  String get passcodeCurrent => 'Senha atual';

  @override
  String get passcodeNewAgain => 'A nova de novo';

  @override
  String get passcodeOldBackupsNote =>
      'Os arquivos de backup que você já fez continuarão abrindo com a senha antiga.';

  @override
  String get passcodeWordsNote =>
      'Suas doze palavras de recuperação não mudam e continuam funcionando.';

  @override
  String get licencesFonts =>
      'Toda fonte aqui está sob a SIL Open Font License. Nada é baixado — elas vêm dentro do app.';

  @override
  String get licencesSource =>
      'O próprio Lamplight é GPL-3.0 com uma exceção para lojas de aplicativos. O código-fonte é a licença: qualquer um pode lê-lo e conferir que o app faz o que esta tela diz.';

  @override
  String get licencesUnreadable => 'Esse arquivo de licença não pôde ser lido.';

  @override
  String get appearanceSample =>
      'Chuva a tarde toda. Fiz chá, li meio capítulo, esqueci o que queria dizer e escrevi isto no lugar.';

  @override
  String get appearanceChromeNote => 'Botões e rótulos continuam assim';

  @override
  String get appearanceSizeNote =>
      'Isto vem por cima do tamanho de texto do próprio telefone, então se você já aumentou lá, aqui aumenta ainda mais.';

  @override
  String get voicePause => 'Pausar';

  @override
  String get importIntro =>
      'Se você escreveu um diário em outro lugar, o Lamplight consegue trazer — desde que sejam arquivos de texto com a data no nome.';

  @override
  String get importHowDates =>
      'Ele lê arquivos de texto e procura uma data no nome — 2026-08-24, ou 24 agosto 2026 — em qualquer parte do nome do arquivo ou das pastas acima.';

  @override
  String get importAmbiguousDates =>
      'Datas como 03-04-2026 são puladas de propósito. Em alguns países é três de abril e em outros quatro de março, e adivinhar errado colocaria um ano da sua vida nos dias errados sem avisar.';

  @override
  String get importFormats =>
      'O Lamplight lê texto simples: .txt, .md, .org, .log e outros, inclusive arquivos sem extensão nenhuma. Se seu diário está em outro formato, exporte antes como texto.';

  @override
  String get importAtStartOfDay =>
      'Vão ficar no começo de cada dia, porque o nome do arquivo dá a data mas não a hora. Nada do que já está no Lamplight é mudado ou removido, e rodar isto duas vezes não faz cópias.';

  @override
  String get importFileDateNote =>
      'Coloca no dia em que o arquivo foi alterado pela última vez. Se a pasta foi copiada entre aparelhos, esse pode ser o dia da cópia e não o dia em que você escreveu.';

  @override
  String get importSkippedNote =>
      'Estes serão pulados. Ficam exatamente onde estão — nada é movido ou apagado da sua pasta.';

  @override
  String get restoreChooseNote =>
      'Escolha seu arquivo de backup. Ele vai se chamar algo como Lamplight-2026-08-18.vault.';

  @override
  String get restorePasscodeNote =>
      'Digite a senha deste arquivo — a que estava valendo quando o backup foi feito.';

  @override
  String get restoreWordsNote =>
      'Digite as doze palavras, na ordem, separadas por espaços.';

  @override
  String get restoreDoNotClose => 'Não feche o Lamplight até isto terminar.';

  @override
  String get exportIntro =>
      'Isto escreve tudo o que há no Lamplight numa pasta que você escolher, como arquivos comuns — um arquivo de texto por dia, e cada foto, vídeo, nota de voz e documento com seu próprio nome.';

  @override
  String get exportNoLamplightNeeded =>
      'Nada nessa pasta precisa do Lamplight para abrir. Se este app um dia parar de funcionar, ou você parar de usar, suas notas continuam abrindo em qualquer coisa que leia texto.';

  @override
  String get exportWhichOneBody =>
      'Uma cópia legível serve para ler, para levar a outro aplicativo, ou para guardar algo depois de parar de usar o Lamplight. Ela não é protegida.\n\nUm arquivo de backup serve para ter o Lamplight de volta exatamente como estava — um telefone novo, ou um que quebrou. Ele fica trancado com sua senha, então dá para guardar em qualquer lugar, inclusive na nuvem.\n\nA maioria das pessoas quer o backup. Faça também uma cópia legível se quiser ter certeza de nunca ficar na mão.';

  @override
  String get exportNotLockedBody =>
      'Ela não tem senha nenhuma. Quem abrir aquela pasta pode ler tudo. Deixe num lugar em que isso esteja bem para você — e se você só quer algo seguro para guardar, use Backup.';

  @override
  String get backupConfirmNote =>
      'Confirme sua senha. Este arquivo pode destrancar tudo, então fazer um deveria ser algo que você quis mesmo.';

  @override
  String get backupKeepSafeNote =>
      'Seu backup fica trancado com a senha que você tem agora. Guarde onde confiar — a nuvem serve, porque o arquivo é ilegível sem essa senha. Nós nunca a vemos.';

  @override
  String get backupRestoreWarning =>
      'Abrir um backup substitui tudo o que está no Lamplight agora. Suas notas atuais ficam de lado até ficar provado que as restauradas abrem.';

  @override
  String get folderWhatItIs =>
      'Uma pasta é um fio que atravessa seus dias — uma pessoa, um lugar, uma fase.';

  @override
  String get folderNothingMoves =>
      'Nada se muda para uma pasta. Uma anotação continua no dia dela e aparece aqui também.';

  @override
  String get folderDeleteNote =>
      'A pasta some. Tudo o que estava nela continua exatamente onde estava, no seu próprio dia.';

  @override
  String get folderNoneInHere =>
      'Nada aqui ainda. Segure algo num dia e escolha “Adicionar a uma pasta”.';

  @override
  String get passcodeRuleLength => 'Oito caracteres ou mais.';

  @override
  String get passcodeRuleWords =>
      'Algumas palavras comuns de que você lembre valem mais que uma curta cheia de símbolos.';

  @override
  String get passcodeNoMatch => 'As duas ainda não coincidem.';

  @override
  String get docCopyInClear =>
      'A cópia é escrita sem criptografia, então qualquer app que consiga ler seus arquivos consegue lê-la. O que fica dentro do Lamplight continua criptografado de qualquer jeito.';

  @override
  String docPageOf(String page, String total) {
    return '$page de $total';
  }

  @override
  String get transcribeTookTooLong =>
      'Essa gravação demorava demasiado a ser transcrita, por isso o Lamplight deixou de esperar. Vai tentar mais tarde.';

  @override
  String get transcribeCouldNotWriteDown =>
      'Não foi possível transcrever essa gravação.';

  @override
  String get transcribeRecordingIsSafe =>
      'A gravação em si está a salvo. O Lamplight vai tentar outra vez.';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$at de $total';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · editada';
  }

  @override
  String get docCouldNotOpen => 'Não foi possível abrir esse documento.';

  @override
  String albumThisOne(Object thing) {
    return 'Este $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'Este $thing — $index de $total';
  }

  @override
  String get albumCaptionThese => 'Escrever algo sobre estes';

  @override
  String get albumCaptionThis => 'Escrever algo';

  @override
  String get albumCaptionEdit => 'Alterar o que está escrito';

  @override
  String albumOthersStay(Object count) {
    return 'Os outros $count ficam. Este vai para o lixo durante 30 dias.';
  }

  @override
  String get albumGoesToTrash => 'Vai para o lixo durante 30 dias.';

  @override
  String get photoCouldNotOpen => 'Não foi possível abrir esta imagem.';

  @override
  String get photoMayBeDamaged => 'Pode estar danificada.';

  @override
  String get docTooBig =>
      'Este é demasiado grande para abrir dentro do Lamplight. Pode guardar uma cópia e abri-lo noutro sítio.';

  @override
  String docPages(Object count) {
    return '$count páginas';
  }

  @override
  String get docFileEmpty => 'Este ficheiro está vazio.';

  @override
  String videoTooBig(Object size) {
    return 'Este vídeo é demasiado grande para reproduzir aqui — $size. Não será escrito sem proteção para contornar isso. Guarde uma cópia para o ver noutro sítio.';
  }

  @override
  String get videoNotAvailableHere =>
      'Esta parte da aplicação não está disponível neste telemóvel.';

  @override
  String get videoCouldNotOpen => 'Não foi possível abrir este vídeo.';

  @override
  String get docGoToPage => 'Ir para uma página';

  @override
  String get docGo => 'Ir';

  @override
  String get docPageCouldNotBeDrawn => 'Não foi possível desenhar esta página.';

  @override
  String get passcodeRuleStronger =>
      'Mais uma ou duas palavras deixariam bem mais difícil de adivinhar.';

  @override
  String get backupAutoFooter =>
      'Os backups automáticos acontecem quando você abre o Lamplight, se algo mudou desde o último. Ficam trancados com sua senha, igual a um que você faça.';

  @override
  String get aboutHowKeptBody =>
      'Sem conta. Sem servidor. Nada sai deste telefone.\n\nSuas notas ficam trancadas com sua senha, e a chave é feita a partir dela — então não existe cópia dela em lugar nenhum, nem conosco.';

  @override
  String get aboutFree =>
      'O Lamplight é gratuito e sempre será. Não há nada para desbloquear.';

  @override
  String get backupOnItsOwn => 'Sozinho';

  @override
  String get actionDismiss => 'Dispensar';

  @override
  String importRange(String from, String to) {
    return 'De $from a $to.';
  }

  @override
  String get sizeOneCopy =>
      'O Lamplight guarda uma cópia. O que você escolher aqui é o que você vai ter.';

  @override
  String get sizeAddAlways => 'Adicionar e não perguntar mais';

  @override
  String get trashNothingHere => 'Não há nada aqui.';

  @override
  String get appearanceAaQuiet => 'Aa\ncalmo';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trancando em cerca de $count segundos.',
      one: 'Trancando em cerca de um segundo.',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => 'Você muda isso em Trancar e segurança.';

  @override
  String get openingLabel => 'O Lamplight está abrindo';

  @override
  String get recordingNoMic =>
      'O Lamplight não pode usar o microfone. Você pode liberar nas configurações do telefone, em Aplicativos.';

  @override
  String get recordingPaused => 'Pausado. Nada está sendo ouvido.';

  @override
  String get videoOpening => 'Abrindo o vídeo…';

  @override
  String albumRemoveThis(String thing) {
    return 'Remover $thing';
  }

  @override
  String get revisionsNote =>
      'O que dizia antes de você mudar. Nada aqui é botão — você pode selecionar o texto e copiar.';

  @override
  String get composerSemantic => 'Escreva algo para este dia';

  @override
  String importStripAdding(String name) {
    return 'Adicionando $name';
  }

  @override
  String passcodeAtLeast(int count) {
    return 'Pelo menos $count caracteres';
  }

  @override
  String get searchKindAll => 'Tudo';

  @override
  String get searchKindWords => 'Palavras';

  @override
  String get searchKindVoice => 'Voz';

  @override
  String get searchKindPhotos => 'Fotos';

  @override
  String get searchKindFiles => 'Arquivos';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pelo menos $count caracteres',
      one: 'Pelo menos 1 caractere',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count dias',
      one: 'Falta 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => 'Vai hoje';

  @override
  String restoreMadeOn(String date) {
    return 'Feito em $date';
  }

  @override
  String restoreDone(String entries, String days) {
    return 'Restaurados $entries em $days. Bem-vindo de volta.';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sem data que o Lamplight consiga ler',
      one: '1 sem data que o Lamplight consiga ler',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return 'Anotação das $time. Toque para editar.';
  }

  @override
  String entrySemanticEdited(String time) {
    return 'Anotação das $time, editada. Toque para editar.';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when. $body. Toque para ir àquele dia.';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$what das $time. Toque duas vezes para abrir.';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date, hoje';
  }

  @override
  String get yearGridNothing => 'Nada neste dia';

  @override
  String get calendarNothing => 'Nada neste dia';

  @override
  String importStripCounted(String name, String counted) {
    return 'Adicionando $name$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'Cada build carrega uma assinatura que só o autor consegue fazer. Esta é a da cópia que você tem. Compare com a impressão digital publicada junto ao código-fonte — se baterem, este é o app que aquele código constrói.';

  @override
  String get searchKindVideo => 'Vídeo';

  @override
  String get semanticOn => 'ativado';

  @override
  String andMore(int count) {
    return 'e mais $count';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anotações',
      one: '1 anotação',
      zero: 'nada',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'Feito';

  @override
  String get checkNotYet => 'Ainda não';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'Use o seu código.';

  @override
  String get searchWordsExample => 'qualquer coisa que você escreveu';

  @override
  String get searchAFile => 'Um ficheiro';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'Uma pasta';

  @override
  String get searchFolderExample => 'o nome que você deu';

  @override
  String get searchByFileName => 'pelo nome do ficheiro';

  @override
  String get searchARecording => 'Uma gravação';

  @override
  String get searchAnEntry => 'Uma entrada';

  @override
  String get sizeThisOne => 'isto';

  @override
  String get sizeTheseOnes => 'estes';

  @override
  String get passcodeOneMoreCharacter => 'Mais um caractere.';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mais $count caracteres — $minimum é o mínimo.',
      one: 'Mais 1 caractere — $minimum é o mínimo.',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious =>
      'Isso é das primeiras coisas que qualquer pessoa tentaria. Escolha outra.';

  @override
  String get passcodeSameCharacter => 'Esse é o mesmo caractere repetido.';

  @override
  String get passcodeStraightRun =>
      'Essa é uma sequência seguida de caracteres.';

  @override
  String attachmentLoading(String time) {
    return 'Anexo às $time, a carregar';
  }

  @override
  String videoSemantic(String time, String length) {
    return 'Vídeo às $time, $length. Toque duas vezes para ver.';
  }

  @override
  String voiceSemantic(String time, String length) {
    return 'Nota de voz às $time, $length. Toque duas vezes para ouvir.';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return 'Ficheiro às $time, $name, $size. Toque duas vezes para abrir.';
  }

  @override
  String get lengthUnknown => 'duração desconhecida';

  @override
  String get settingsLockNone => 'sem bloqueio automático';

  @override
  String settingsLockAfter(String duration) {
    return 'após $duration';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'Código, impressão digital, $lock';
  }

  @override
  String get keptNoNetworkTitle => 'Nunca sai daqui';

  @override
  String get keptNoNetworkBody =>
      'O Lamplight não consegue usar a internet. Não é que «não use» — não consegue: o Android recusa-lhe a permissão, e pode verificá-lo você mesmo nas definições de aplicações do telemóvel em cerca de trinta segundos.';

  @override
  String get keptPasscodeTitle => 'O seu código é a chave';

  @override
  String get keptPasscodeBody =>
      'A chave que abre as suas notas é criada a partir do seu código sempre que desbloqueia. Não é guardada em lado nenhum, por isso não há cópia para encontrar, perder ou entregar.';

  @override
  String get keptForgetTitle => 'Se o esquecer';

  @override
  String get keptForgetBody =>
      'As suas doze palavras são a única outra forma de entrar. Aqui ninguém pode repor um código, e esse é o mesmo facto do ponto anterior — uma aplicação que o pudesse deixar entrar de novo também poderia deixar entrar outra pessoa.';

  @override
  String get keptNothingReadableTitle => 'Não fica nada legível por aí';

  @override
  String get keptNothingReadableBody =>
      'Fotografias, gravações e ficheiros são cifrados antes de tocarem no armazenamento. Nada é alguma vez escrito em claro, nem sequer por instantes enquanto o vê.';

  @override
  String get keptLocksItselfTitle => 'Bloqueia-se sozinho';

  @override
  String get keptLocksItselfBody =>
      'No momento em que o Lamplight passa para segundo plano, as chaves são destruídas. As capturas de ecrã são bloqueadas e a aplicação não aparece na pré-visualização de aplicações recentes.';

  @override
  String get keptBackUpTitle => 'Faça uma cópia';

  @override
  String get keptBackUpBody =>
      'Está tudo neste telemóvel e em mais lado nenhum, o que é o objetivo e é também o risco. Uma cópia de segurança é um único ficheiro cifrado que só o seu código abre. Guarde uma algures.';
}
