// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'Escribe tu contraseña.';

  @override
  String get lockWrongPasscode => 'Eso no ha abierto la caja fuerte.';

  @override
  String get lockCheckAndRetry => 'Revisa la contraseña e inténtalo de nuevo.';

  @override
  String get lockForgot => 'He olvidado mi contraseña';

  @override
  String get lockTypeTwelveWords => 'Escribe tus doce palabras.';

  @override
  String get lockUsePasscodeInstead => 'Usar mi contraseña';

  @override
  String get lockUseFingerprint => 'Usar tu huella';

  @override
  String get lockFingerprintFailed => 'La huella no ha funcionado.';

  @override
  String get lockFingerprintUnavailable => 'La huella no está disponible.';

  @override
  String get lockOpening => 'Abriendo…';

  @override
  String get lockNothingDeleted =>
      'No se ha borrado nada, y no se borrará nada.';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inténtalo de nuevo en $count segundos.',
      one: 'Inténtalo de nuevo en un segundo.',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inténtalo de nuevo en $count minutos.',
      one: 'Inténtalo de nuevo en un minuto.',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'HOY';

  @override
  String get dayPrevious => 'El día anterior';

  @override
  String get dayNext => 'El día siguiente';

  @override
  String get daySearch => 'Buscar';

  @override
  String get daySettings => 'Ajustes';

  @override
  String get dayChooseDate => 'Elegir otra fecha.';

  @override
  String get dayEmptyToday => '¿Algo que quieras guardar?';

  @override
  String get dayEmptyPast => 'Nada en este día.';

  @override
  String get dayWriteSomething => 'Escribir algo para hoy';

  @override
  String get dayLineAsk => '¿Qué fue este día?';

  @override
  String get dayLineHint => '¿Qué fue este día?';

  @override
  String get dayLineSemantic => 'Di en una línea qué fue este día';

  @override
  String dayLineChange(String note) {
    return 'Este día: $note. Cambiarlo.';
  }

  @override
  String get dayEndOfDay => 'El final del día';

  @override
  String get dayStartOfDay => 'El principio del día';

  @override
  String get firstPageTitle =>
      'Esto está vacío porque todavía no has escrito nada.';

  @override
  String get firstPageShelves =>
      'Los días son los estantes. Lo que guardes queda en el día en que ocurrió, y ahí se queda.';

  @override
  String get firstPageWayWrite => 'Toca esta página para escribir.';

  @override
  String get firstPageWayVoice =>
      'Mantén pulsado el micrófono para decirlo en voz alta.';

  @override
  String get firstPageWayAttach =>
      'Añade una fotografía, un vídeo o un documento.';

  @override
  String get firstPagePromise => 'Nada de esto sale de este teléfono.';

  @override
  String get firstPageSemantic => 'Escribe lo primero en tu diario';

  @override
  String get captureVoice => 'Grabar una nota de voz';

  @override
  String get capturePhoto => 'Hacer o elegir una foto';

  @override
  String get captureFile => 'Adjuntar un archivo';

  @override
  String get backupNeverMade =>
      'Aquí no hay ninguna copia de seguridad. Si se desinstala esta aplicación, tus notas se van con ella.';

  @override
  String get backupStale => 'Hace tiempo de la última copia de seguridad.';

  @override
  String get backupOutOfDate =>
      'Tu copia de seguridad sigue abriéndose con tu contraseña anterior.';

  @override
  String get backupAction => 'Copia de seguridad';

  @override
  String folderAlsoIn(String name) {
    return 'También en $name. Abrir la carpeta.';
  }

  @override
  String get folderStaysHere =>
      'Se queda donde está. Una carpeta es un segundo sitio donde encontrarlo.';

  @override
  String get folderAddTo => 'Añadir a una carpeta';

  @override
  String get folderNew => 'Carpeta nueva';

  @override
  String get folderNoneYet =>
      'Todavía no hay carpetas. Una por persona, o por etapa — lo que sea que vuelvas a mirar.';

  @override
  String folderLesson(String day, String folder) {
    return 'Sigue en $day. También en $folder.';
  }

  @override
  String get actionDone => 'Hecho';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Borrar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionNotNow => 'Ahora no';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsSecurity => 'Bloqueo y seguridad';

  @override
  String get settingsYourNotes => 'Tus notas';

  @override
  String get settingsBackup => 'Copia de seguridad';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageNote =>
      'Las palabras que usa la aplicación. Lo que escribes es tuyo, en cualquier idioma, sea cual sea este ajuste.';

  @override
  String get settingsLanguageSystem => 'Seguir al teléfono';

  @override
  String get entryMattered => 'Esto importó';

  @override
  String get entryMarked => 'Marcada como una que importó.';

  @override
  String get entryMarkRemoved => 'Marca quitada.';

  @override
  String get entryDeleted => 'Eliminado.';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versiones anteriores',
      one: 'Una versión anterior',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => 'Conserva las palabras';

  @override
  String entryKindInTrash(Object kind) {
    return 'El $kind está en la papelera.';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return 'El $kind está en la papelera. Las palabras siguen aquí.';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count anotaciones y todas sus versiones anteriores. Esto no se puede deshacer.',
      one: 'Una anotación y todas sus versiones anteriores. Esto no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => 'Anotación vacía';

  @override
  String get kindPhoto => 'Foto';

  @override
  String get kindVideo => 'Vídeo';

  @override
  String get kindRecording => 'Grabación';

  @override
  String get kindFile => 'Archivo';

  @override
  String get entryNoLongerMarked => 'Ya no está marcado';

  @override
  String get entryFindAgain => 'Vuelve a encontrarlo desde la búsqueda';

  @override
  String get searchGoTo => 'Ir a';

  @override
  String get searchFolders => 'Carpetas';

  @override
  String get searchEntriesOne => '1 entrada';

  @override
  String searchEntriesMany(int count) {
    return '$count entradas';
  }

  @override
  String get searchNothingFound => 'Nada coincide con eso.';

  @override
  String get searchEverythingInstead => 'Buscar en todo';

  @override
  String get searchNoneOfThese => 'Todavía no hay nada de eso.';

  @override
  String get onboardNoAccount => 'No hay ninguna cuenta.';

  @override
  String get onboardPromiseBody =>
      'Tus notas se quedan en este teléfono.\nNo tenemos servidor. No podemos leerlas.\nTampoco podemos recuperarlas.';

  @override
  String get onboardBegin => 'Empezar';

  @override
  String get onboardHaveBackup => 'Tengo una copia de seguridad';

  @override
  String get onboardSetPasscode => 'Crea una contraseña';

  @override
  String get onboardPasscodeBody =>
      'Es lo único que abre tus notas. Una frase que puedas recordar es más fuerte que cuatro dígitos.';

  @override
  String get onboardPasscodeLabel => 'Contraseña';

  @override
  String get onboardPasscodeAgain => 'Escríbela otra vez';

  @override
  String get onboardSettingUp => 'Preparando…';

  @override
  String get onboardContinue => 'Continuar';

  @override
  String get onboardPasscodesDiffer => 'Esas dos no coinciden.';

  @override
  String get onboardVaultFailed => 'No se ha podido crear tu caja fuerte.';

  @override
  String get onboardVaultFailedThen =>
      'No se ha guardado nada. Inténtalo una vez más.';

  @override
  String get onboardWriteWords => 'Escribe estas doce palabras\nen papel';

  @override
  String get onboardWordsBody =>
      'No tenemos ninguna copia. No podemos enviártelas. No hay ningún correo de soporte que pueda ayudarte.\n\nEn papel, no una captura. Una captura se queda en tu galería, que es el primer sitio donde mira cualquiera.';

  @override
  String get onboardWrittenDown => 'Ya las he escrito';

  @override
  String get onboardCopyWords => 'Copiar las doce palabras';

  @override
  String get onboardClipboardNote =>
      'El portapapeles se borra solo al cabo de un minuto. Hasta entonces, otras aplicaciones pueden leerlo.';

  @override
  String get onboardCopied =>
      'Copiado. Se borra solo en un minuto: pégalo ahora en un sitio seguro.';

  @override
  String get onboardCopyFailed =>
      'No se ha podido copiar. Escribirlas a mano es más seguro de todos modos.';

  @override
  String get onboardCheckThree => 'Comprueba tres de ellas';

  @override
  String get onboardCheckBody =>
      'Así sabemos que el papel está bien, no la pantalla.';

  @override
  String onboardWordNumber(int number) {
    return 'Palabra $number';
  }

  @override
  String onboardWordWrong(int number) {
    return 'La palabra $number no es correcta. Mira lo que escribiste.';
  }

  @override
  String get onboardShowWords => 'Enséñame las palabras otra vez';

  @override
  String get onboardFingerprintTitle => '¿Abrirla con tu huella?';

  @override
  String get onboardFingerprintBody =>
      'Así no tienes que escribir esa frase cada vez.';

  @override
  String get onboardFingerprintExplain =>
      'Tu frase sigue siendo la llave. La huella solo abre esta caja fuerte, solo en este teléfono, y Android la desactiva por su cuenta si las huellas del teléfono cambian, para que nadie pueda añadir la suya y entrar. Nunca forma parte de una copia de seguridad.';

  @override
  String get onboardFingerprintWaiting => 'Esperando tu dedo…';

  @override
  String get onboardFingerprintUse => 'Usar mi huella';

  @override
  String get onboardFingerprintFailed => 'Eso no ha funcionado.';

  @override
  String get onboardFingerprintVaultShut =>
      'Lamplight cerró la caja fuerte mientras no estabas. Tu código sigue abriéndola y puedes activar la huella más tarde en Ajustes.';

  @override
  String get onboardOneLastThing => 'Una última cosa';

  @override
  String get onboardNameBody =>
      '¿Cómo quieres que Lamplight te llame? Se queda en este teléfono, y puedes cambiarlo o dejarlo en blanco.';

  @override
  String get onboardFingerprintOn =>
      'Tu huella abrirá Lamplight a partir de ahora.';

  @override
  String get onboardYourName => 'Tu nombre';

  @override
  String get onboardStartWriting => 'Empezar a escribir';

  @override
  String get onboardSkip => 'Omitir';

  @override
  String get settingsGroupLook => 'Cómo se ve y cómo habla';

  @override
  String get settingsGroupWhoCanOpen => 'Quién puede abrirlo';

  @override
  String get settingsGroupKeeping => 'Guardarlo, y llevártelo';

  @override
  String get settingsAppearanceNote => 'Tema, letra, color, página';

  @override
  String get settingsFolders => 'Carpetas';

  @override
  String get settingsFoldersNote => 'Personas, lugares, etapas';

  @override
  String get settingsMedia => 'Multimedia';

  @override
  String get settingsMediaNote => 'Fotos, vídeo, sonido y documentos';

  @override
  String get mediaGroupDocuments => 'Documentos';

  @override
  String get mediaDocumentsKept => 'Se guardan exactamente como llegaron';

  @override
  String get mediaDocumentsFooter =>
      'Un PDF o un archivo de Word ya viene comprimido por dentro, así que comprimirlo otra vez ahorra alrededor del cinco por ciento. Para que se notara habría que volver a codificar las imágenes que contiene, y eso emborrona para siempre la letra pequeña de un escaneo — algo que descubrirías años después, el día que necesitaras leerlo.';

  @override
  String get settingsTrash => 'Papelera';

  @override
  String get settingsTrashNote => 'Entradas borradas, se guardan 30 días';

  @override
  String get settingsReadableCopy => 'Copia legible';

  @override
  String get settingsReadableCopyNote =>
      'Markdown y tus archivos, en una carpeta que elijas';

  @override
  String get settingsBringIn => 'Traer un diario antiguo';

  @override
  String get settingsBringInNote =>
      'Archivos de texto de otra aplicación, ordenados por su fecha';

  @override
  String get settingsKeepingFooter =>
      'Una copia de seguridad va cerrada con tu contraseña, igual que la caja fuerte. Una copia legible no va cerrada de ninguna manera: son archivos normales en una carpeta que tú eliges.';

  @override
  String get backupNever => 'Sin copia de seguridad';

  @override
  String get backupToday => 'Copia hecha hoy';

  @override
  String get backupYesterday => 'Copia hecha ayer';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copia hecha hace $count días',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => 'Al entrar';

  @override
  String get mediaGroupVoice => 'Notas de voz';

  @override
  String get mediaIncomingFooter =>
      'Lamplight nunca guarda una segunda copia más pequeña: lo que elijas aquí es lo que se guarda, y el original no queda en ningún otro sitio.';

  @override
  String get mediaVoiceFooter =>
      'La transcripción ocurre en este teléfono, con el reconocedor que Android ya trae. Nada de lo que digas en Lamplight se envía a ninguna parte, y la aplicación no tiene permiso para enviarlo.';

  @override
  String get mediaPhotoSize => 'Tamaño de las fotos';

  @override
  String get mediaVideoSize => 'Tamaño de los vídeos';

  @override
  String get mediaAskEachTime => 'Preguntar cada vez';

  @override
  String get accentAmber => 'Ámbar';

  @override
  String get accentAmberNote => 'Una lámpara de noche. El de siempre.';

  @override
  String get accentRose => 'Rosa';

  @override
  String get accentRoseNote => 'Rosa cálido. Más suave que el ámbar.';

  @override
  String get accentSage => 'Salvia';

  @override
  String get accentSageNote => 'Verde tranquilo. El más sereno de los seis.';

  @override
  String get accentSlate => 'Pizarra';

  @override
  String get accentSlateNote => 'Gris azulado frío. El más neutro.';

  @override
  String get accentPlum => 'Ciruela';

  @override
  String get accentPlumNote => 'Morado intenso.';

  @override
  String get accentEmber => 'Brasa';

  @override
  String get accentEmberNote => 'Naranja quemado. El más cálido.';

  @override
  String get surfacePlain => 'Lisa';

  @override
  String get surfacePlainNote => 'Una página sin nada.';

  @override
  String get surfacePaper => 'Papel';

  @override
  String get surfacePaperNote =>
      'Un grano suave, para que la página se sienta como algo material. La de siempre.';

  @override
  String get surfaceLamplit => 'Con lámpara';

  @override
  String get surfaceLamplitNote => 'Papel, con la lámpara encendida.';

  @override
  String get surfaceStarMap => 'Mapa estelar';

  @override
  String get surfaceStarMapNote =>
      'Un solo cielo, girando con el reloj. Nunca igual dos veces en un día.';

  @override
  String get rulingNone => 'Nada';

  @override
  String get rulingNoneNote => 'Nada impreso en la página.';

  @override
  String get rulingLines => 'Renglones';

  @override
  String get rulingLinesNote => 'Rayada como un cuaderno.';

  @override
  String get rulingIsometric => 'Isométrica';

  @override
  String get rulingIsometricNote =>
      'Papel de dibujo técnico, para pensar en tres dimensiones.';

  @override
  String get rulingTriangle => 'Triángulos';

  @override
  String get rulingTriangleNote => 'Un campo de triángulos equiláteros.';

  @override
  String get rulingDots => 'Cuadrícula de puntos';

  @override
  String get rulingDotsNote =>
      'Un punto en cada cruce. La más discreta de las cuatro.';

  @override
  String get faceSystem => 'Del sistema';

  @override
  String get faceSystemNote => 'La que use el resto de tu teléfono.';

  @override
  String get faceSerif => 'Serif del sistema';

  @override
  String get faceSerifNote => 'La serif propia de tu teléfono.';

  @override
  String get faceCalmNote => 'Bordes suaves, letras anchas.';

  @override
  String get faceModernNote => 'Ajustada y actual.';

  @override
  String get faceOldStyleNote => 'Una letra de libro del siglo XVI.';

  @override
  String get facePlayfulNote => 'Redonda y alegre.';

  @override
  String get faceChildlikeNote => 'Un cuaderno de clase.';

  @override
  String get faceHandwrittenNote =>
      'Letra a mano, y aun así se lee de corrido.';

  @override
  String get faceMedievalNote => 'La mano de un copista. Un solo grosor.';

  @override
  String get faceMonoNote => 'Todas las letras del mismo ancho.';

  @override
  String get qualityOriginal => 'Dejar el original';

  @override
  String get qualityBalanced => 'Equilibrado';

  @override
  String get qualitySmaller => 'Más pequeño';

  @override
  String get photoOriginalNote =>
      'Tal como la hizo tu cámara. Los archivos más grandes, y además conservan el lugar donde se tomó la foto, que Lamplight normalmente borra.';

  @override
  String get photoBalancedNote =>
      'Mucho más pequeño, y difícil de distinguir del original. El de siempre.';

  @override
  String get photoSmallerNote =>
      'La mitad otra vez. Puede que lo notes si recortas mucho.';

  @override
  String get videoOriginalNote =>
      'Tal como lo grabó tu cámara. Con diferencia, los archivos más grandes.';

  @override
  String get videoBalancedNote =>
      'Mucho más pequeño, y difícil de distinguir del original. El de siempre.';

  @override
  String get videoSmallerNote =>
      'La mitad otra vez. Puede que lo notes en una pantalla grande.';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceThemeDark => 'Oscuro';

  @override
  String get appearanceThemeLight => 'Claro';

  @override
  String get appearanceThemeAuto => 'Del sistema';

  @override
  String get appearanceThemeAutoNote =>
      'Sigue el ajuste de claro y oscuro de tu teléfono.';

  @override
  String get appearanceFont => 'Letra';

  @override
  String get appearanceSize => 'Tamaño';

  @override
  String get appearanceColour => 'Color';

  @override
  String get appearancePage => 'Página';

  @override
  String get appearanceRuling => 'Pauta';

  @override
  String get daySavedToToday => 'Guardado en hoy.';

  @override
  String get dayAddedToToday => 'Añadido a hoy.';

  @override
  String get entryEditWords => 'Editar las palabras';

  @override
  String get entryDeleteBlock => 'Borrar el bloque entero';

  @override
  String entrySavedAs(String name) {
    return 'Guardado como $name.';
  }

  @override
  String entryAddedToFolder(String name) {
    return 'También en $name.';
  }

  @override
  String get entrySaveCopy => 'Guardar una copia';

  @override
  String get entrySaveCopyNote => 'Donde tú elijas, fuera de Lamplight';

  @override
  String get capturePhotoTake => 'Hacer una foto';

  @override
  String get capturePhotoChoose => 'Elegir de tus fotos';

  @override
  String get composerHintToday => 'Escribe sobre hoy…';

  @override
  String get composerHintPast => 'Escribe sobre este día…';

  @override
  String get composerNewBlock => 'Bloque nuevo';

  @override
  String get voiceShowTranscript => 'Ver lo que se dijo';

  @override
  String get voiceHideTranscript => 'Ocultar lo que se dijo';

  @override
  String get voiceTranscriptTitle => 'Lo que se dijo';

  @override
  String get entryEdited => ', editado';

  @override
  String photoSemantic(String time) {
    return 'Foto de las $time. Toca dos veces para verla.';
  }

  @override
  String get sizeThisPhoto => 'esta foto';

  @override
  String get sizeThesePhotos => 'estas fotos';

  @override
  String get sizeThisVideo => 'este vídeo';

  @override
  String get sizeTheseVideos => 'estos vídeos';

  @override
  String sizeQuestion(String what) {
    return '¿De qué tamaño quieres guardar $what?';
  }

  @override
  String get trashNote =>
      'Lo borrado se queda aquí 30 días, y luego se va del todo.';

  @override
  String get trashConfirm => '¿Borrar esto para siempre?';

  @override
  String get trashKeep => 'Quedármelos';

  @override
  String get trashDeleteForGood => 'Borrar para siempre';

  @override
  String get trashPutBack => 'Devolver';

  @override
  String trashPutBackOn(String day) {
    return 'Devuelto al $day.';
  }

  @override
  String get trashEmpty => 'Vaciar la papelera';

  @override
  String get folderMakeFirst => 'Crear la primera';

  @override
  String folderDeleteAsk(String name) {
    return '¿Borrar «$name»?';
  }

  @override
  String get folderKeepIt => 'Quedármela';

  @override
  String get folderDeleteIt => 'Borrar la carpeta';

  @override
  String get folderRename => 'Cambiar el nombre';

  @override
  String get folderDeleteThis => 'Borrar esta carpeta';

  @override
  String folderTakenOut(String name) {
    return 'Sacado de $name. Sigue en su día.';
  }

  @override
  String get searchHint => 'Palabras, una fecha, un nombre…';

  @override
  String get searchBack => 'Atrás';

  @override
  String get searchClear => 'Limpiar';

  @override
  String searchNothingMatches(String query) {
    return 'No hay nada que coincida con «$query».';
  }

  @override
  String get searchWhatMattered => 'LO QUE IMPORTÓ';

  @override
  String get searchADate => 'Una fecha';

  @override
  String get searchDateExample => '16 marzo 2006 · marzo 2006 · ayer';

  @override
  String get searchWhatYouCanType => 'Qué puedes buscar';

  @override
  String get searchTryDate => 'ayer';

  @override
  String get searchSaidOutLoud => 'dicho en voz alta';

  @override
  String get searchAPhotograph => 'Una foto';

  @override
  String get searchAVideo => 'Un vídeo';

  @override
  String get securityWhileOpen => 'Mientras la app está abierta';

  @override
  String get securityLockFooter =>
      'Lamplight siempre se cierra en cuanto pasa a segundo plano. Esto solo decide cuánto espera mientras sigues dentro.';

  @override
  String get securityLockAfter => 'Cerrar tras';

  @override
  String get securityOneHour => '1 hora';

  @override
  String get securityYourPasscode => 'Tu contraseña';

  @override
  String get securityPasscodeFooter =>
      'Tu contraseña es la llave. No se guarda en ninguna parte —ni en este teléfono ni en ningún otro sitio—, así que nadie puede ser obligado a entregarla, y nadie puede recuperarla por ti.';

  @override
  String get securityChangePasscode => 'Cambiar la contraseña';

  @override
  String get securityScreenshots => 'Capturas de pantalla';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight bloquea las capturas para que quien coja tu teléfono no pueda fotografiar tus notas, y para que no aparezcan en la vista de aplicaciones recientes. Puedes desactivarlo en tu propio teléfono.';

  @override
  String get securityAllowScreenshots => 'Permitir capturas';

  @override
  String get securityScreenshotsOn =>
      'Tus notas se verán en las apps recientes';

  @override
  String get securityScreenshotsOff =>
      'Las apps recientes muestran una página en blanco';

  @override
  String get securityCouldNotChange => 'No se ha podido cambiar.';

  @override
  String get securityNothingChanged => 'Nada de tu bloqueo ha cambiado.';

  @override
  String get securityPromptAutomatic => 'La petición aparece sola';

  @override
  String get securityPromptOnTap => 'Toca la huella cuando quieras usarla';

  @override
  String get mediaAskEachTimeOn =>
      'Se te pregunta qué tamaño guardar para fotos y vídeos al añadirlos.';

  @override
  String get mediaAskEachTimeOff =>
      'Desactivado. Se usan los dos tamaños de arriba sin preguntar.';

  @override
  String get passcodeNew => 'Código nuevo';

  @override
  String get securityFingerprint => 'Huella';

  @override
  String get securityFingerprintFooter =>
      'Tu frase sigue siendo la llave. La huella solo abre esta caja fuerte, solo en este teléfono, y Android la desactiva por su cuenta si las huellas del teléfono cambian, para que nadie pueda añadir la suya y entrar. Nunca forma parte de una copia de seguridad.';

  @override
  String get securityUnlockWithFingerprint => 'Abrir con mi huella';

  @override
  String get securityAskOnOpen => 'Preguntar nada más abrir Lamplight';

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
  String get securityDefaultNote => 'Lo de siempre.';

  @override
  String get securityHourNote => 'Para una tarde releyendo.';

  @override
  String get securityNeverNote => 'Sigue cerrándose en cuanto sales de la app.';

  @override
  String get calendarGoToDate => 'Ir a una fecha';

  @override
  String get dayHasWriting => 'escritura';

  @override
  String get dayHasPhoto => 'una foto';

  @override
  String get dayHasVideo => 'un vídeo';

  @override
  String get dayHasVoice => 'una nota de voz';

  @override
  String get dayHasFile => 'un archivo';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count, $kinds';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listAnd(Object last, Object most) {
    return '$most y $last';
  }

  @override
  String get integrityNothingUnusual =>
      'Nada raro en este teléfono. Lamplight funciona como debe.';

  @override
  String get calendarPreviousYear => 'Año anterior';

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextYear => 'Año siguiente';

  @override
  String get calendarNextMonth => 'Mes siguiente';

  @override
  String get calendarBackToMonth => 'Volver al mes';

  @override
  String get calendarWholeYear => 'El año entero';

  @override
  String get calendarBackToThisMonth => 'Volver a este mes';

  @override
  String get calendarNothingThisYear => 'Todavía no hay nada en este año.';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$entries en $days.';
  }

  @override
  String get folderNothingInIt => 'Todavía no hay nada';

  @override
  String get onThisDayOneYear => 'Hoy hace un año';

  @override
  String onThisDayYears(Object years) {
    return 'Hoy hace $years años';
  }

  @override
  String wheelYear(Object year) {
    return 'Año $year';
  }

  @override
  String get calendarBackToBrowsing => 'Volver a hojear';

  @override
  String get calendarToday => 'Hoy';

  @override
  String get calendarFirstEntry => 'Tu primera anotación';

  @override
  String get calendarGoToThisDay => 'Ir a este día';

  @override
  String get calendarDensityNote =>
      'El color dice cuánto hay en un día, de nada a mucho.';

  @override
  String get calendarLess => 'Menos';

  @override
  String get calendarMore => 'Más';

  @override
  String get calendarGoToToday => 'Ir a hoy';

  @override
  String get backupTitle => 'Copia de seguridad';

  @override
  String get vaultNothingToBackUp =>
      'Todavía no hay nada en esta caja fuerte que copiar.';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return 'Algo cambió mientras se hacía la copia ($name). Prueba otra vez.';
  }

  @override
  String get vaultTooSmall =>
      'Este archivo es demasiado pequeño para ser una copia de Lamplight.';

  @override
  String get vaultNotALamplightFile =>
      'Este no es un archivo de copia de Lamplight.';

  @override
  String get vaultDamaged => 'Este archivo está dañado y no se puede abrir.';

  @override
  String get vaultKeyringNewerVersion =>
      'Esta caja fuerte se hizo con una versión más nueva de Lamplight. Actualiza la app para abrirla.';

  @override
  String get vaultKeyringDamaged =>
      'El archivo de la llave está dañado y no se puede leer. Si tienes una copia, restaura desde ella.';

  @override
  String get vaultDatabaseNewerVersion =>
      'Esta caja fuerte se hizo con una versión más nueva de Lamplight. Actualiza la app para abrirla: tus notas están intactas y no se ha cambiado nada.';

  @override
  String phraseWrongLength(Object count) {
    return 'Una frase de recuperación tiene 12 palabras. Esta tiene $count.';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '\"$word\" no es una de las palabras de recuperación.';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'Esas palabras no son una frase de recuperación válida. Mira si hay una mal escrita o cambiada de sitio.';

  @override
  String get vaultNewerVersion =>
      'Esta copia se hizo con una versión más nueva de Lamplight. Actualiza la app y prueba otra vez.';

  @override
  String get vaultUnknownCompression =>
      'Esta copia usa una compresión que esta versión no sabe leer.';

  @override
  String get vaultDamagedTryOlder =>
      'Este archivo está dañado y no se puede abrir. Si tienes una copia más antigua, prueba con esa.';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'Esta copia se hizo antes de que las frases de recuperación pudieran abrir copias. Su código es la única forma de entrar.';

  @override
  String get vaultWordsDoNotOpenIt =>
      'Esas palabras no abren este archivo. Puede que sean de otra caja fuerte.';

  @override
  String get vaultWrongPasscode => 'Ese código no abre este archivo.';

  @override
  String vaultMissingPart(Object name) {
    return 'A esta copia le falta una parte de sí misma ($name).';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'Esta copia está dañada ($name tiene un tamaño incorrecto).';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'Esta copia está dañada ($name no coincide).';
  }

  @override
  String get vaultNoVaultInside =>
      'Esta copia no contiene una caja fuerte. Puede que la haya hecho otra app.';

  @override
  String get vaultOutOfOrder =>
      'Este archivo está dañado: su contenido está desordenado.';

  @override
  String get vaultEndsPartWay => 'Este archivo está dañado: termina a medias.';

  @override
  String vaultIncomplete(Object parts) {
    return 'Este archivo está incompleto: tiene $parts de sus partes.';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'Esta copia contiene algo que Lamplight no abrirá ($name).';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anotaciones',
      one: '1 anotación',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => 'Comprobando que se abre…';

  @override
  String get backupCouldNotSave => 'No se ha podido guardar la copia.';

  @override
  String get backupNothingLost =>
      'No se ha perdido nada y tus notas están intactas. Prueba otra vez en un momento.';

  @override
  String get backupLast => 'Última copia';

  @override
  String get backupInTheVault => 'En la caja fuerte';

  @override
  String get restoreCheckingFile => 'Comprobando el archivo…';

  @override
  String get restoreCouldNotOpen => 'No se ha podido abrir ese archivo.';

  @override
  String get restoreCheckItIsTheOne =>
      'Comprueba que es la copia que querías y prueba otra vez.';

  @override
  String get restorePuttingInPlace => 'Colocándola en su sitio…';

  @override
  String get restorePuttingBack => 'Devolviendo tus notas anteriores…';

  @override
  String get restoreCouldNotFinish =>
      'No se ha podido terminar la restauración.';

  @override
  String get restoreBackAsTheyWere => 'Tus notas están como estaban.';

  @override
  String get restoreUsePasscodeInstead => 'Usar el código en su lugar';

  @override
  String get restoreUseWordsInstead => 'Tengo las doce palabras';

  @override
  String get backupCreateFile => 'Crear el archivo';

  @override
  String get backupCreatedChecked => 'Copia creada y comprobada.';

  @override
  String get backupMakeAnother => 'Hacer otra';

  @override
  String get backupRestoreHeading => 'Restaurar';

  @override
  String get backupRestoreFrom => 'Restaurar desde un archivo';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent por ciento';
  }

  @override
  String get restoreTitle => 'Restaurar';

  @override
  String get restoreChooseFile => 'Elegir un archivo';

  @override
  String get restoreUseLatest => 'Usar mi copia más reciente';

  @override
  String get restorePhraseHint => 'recuerda historia industria…';

  @override
  String get restoreAction => 'Restaurar';

  @override
  String get restoreChooseDifferent => 'Elegir otro archivo';

  @override
  String get importChooseFolder => 'Elegir una carpeta';

  @override
  String get importChooseFiles => 'Elegir los archivos en su lugar';

  @override
  String get importChooseFilesNote =>
      'Si Android rechaza tu carpeta — no da a ninguna aplicación Descargas ni la raíz del almacenamiento — elige los archivos directamente. Eso nunca se rechaza.';

  @override
  String get importLooking => 'Mirando dentro de la carpeta…';

  @override
  String get importNoTextFiles => 'No hay archivos de texto en esa carpeta.';

  @override
  String get importChooseDifferentFolder => 'Elegir otra carpeta';

  @override
  String get importUseFileDate => 'Usar la fecha del propio archivo';

  @override
  String get importUseFileDateNote =>
      'Los pone en el día en que el archivo se modificó por última vez. Muchas veces no es el día del que habla.';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Traer $count notas',
      one: 'Traer 1 nota',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return 'Trayendo, $percent por ciento';
  }

  @override
  String get exportChooseFolder => 'Elegir una carpeta y exportar';

  @override
  String get exportSave => 'Guardar una copia legible';

  @override
  String get exportWritten => 'Tu copia está escrita.';

  @override
  String get exportAgain => 'Exportar otra vez';

  @override
  String get exportWhichOne => '¿Cuál quiero?';

  @override
  String get exportNotLocked => 'Esta copia no está cerrada';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadidas $count cosas a hoy.',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'Añadir una nota a esto';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadidos $count.',
      one: 'Añadido.',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => 'No se ha podido leer esa carpeta.';

  @override
  String get importNothingBrought => 'No se ha traído nada.';

  @override
  String get importStoppedPartWay =>
      'La importación del diario se ha detenido a medias.';

  @override
  String get importWhatArrivedKept =>
      'Se ha conservado todo lo que llegó antes de pararse.';

  @override
  String get importNoReadableDates =>
      'Ninguno de esos archivos tiene una fecha que Lamplight sepa leer.';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anotaciones listas para traer.',
      one: '1 anotación lista para traer.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => 'No hay nada nuevo que traer.';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anotaciones traídas.',
      one: '1 anotación traída.',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count ya estaban aquí, así que se han dejado como estaban.';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count no tenían fecha legible y se han omitido.';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count no se han podido leer: $names';
  }

  @override
  String get exportStarting => 'Empezando…';

  @override
  String get exportCouldNotFinish =>
      'No se ha podido terminar la copia legible.';

  @override
  String get exportNothingChanged => 'No ha cambiado nada dentro de Lamplight.';

  @override
  String get importVideoAlreadySmall =>
      'Un vídeo ya era todo lo pequeño que podía ser, así que se ha guardado tal cual.';

  @override
  String get importVideoCouldNotShrink =>
      'Un vídeo no se ha podido reducir en este teléfono, así que se ha guardado entero.';

  @override
  String importOneFailed(String reason) {
    return 'Uno no salió bien: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count no terminaron antes de que Lamplight se cerrara.',
      one: 'Uno no terminó antes de que Lamplight se cerrara.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => 'No quedó nada en el teléfono.';

  @override
  String get nameCardAsk => '¿Qué quieres que ponga aquí?';

  @override
  String get nameCardHint => 'Tu nombre, o lo que quieras';

  @override
  String get reminderGroup => 'Un empujoncito, si te apetece';

  @override
  String get reminderFooter =>
      'Apagado salvo que lo enciendas. Nunca menciona lo que hay en tus notas: no puede, porque funciona con la caja fuerte cerrada. Sin rachas, sin cuentas, nada sobre los días que te saltaste.';

  @override
  String get reminderTitle => 'Recuérdame escribir';

  @override
  String get reminderWhen => 'A qué hora';

  @override
  String get reminderProblemNotAllowed =>
      'Lamplight no tiene permiso para enviar notificaciones.';

  @override
  String get reminderProblemNotificationsOff =>
      'Los ajustes de este teléfono tienen desactivadas las notificaciones de Lamplight.';

  @override
  String get reminderProblemRemindersOff =>
      'Los recordatorios de Lamplight están desactivados en los ajustes de notificaciones de este teléfono.';

  @override
  String get reminderProblemBatterySaving =>
      'Este teléfono ahorra batería frenando a Lamplight. Esa es la razón habitual de que un recordatorio llegue tarde o no llegue.';

  @override
  String get reminderMayNotArrive => 'El recordatorio puede no llegar';

  @override
  String get backupAutomatic => 'Copia automática';

  @override
  String get backupAutomaticDidNotFinish =>
      'La copia automática no ha terminado.';

  @override
  String get backupNothingYet => 'Todavía no hay nada que copiar.';

  @override
  String get backupInProgress => 'Haciendo copia…';

  @override
  String get backupStartsAtUnlock => 'Empieza la próxima vez que desbloquees.';

  @override
  String get backupDoneAutomatically => 'Copia hecha automáticamente.';

  @override
  String get backupLastOneFailed =>
      'La última copia automática no terminó. Lo intentará otra vez la próxima vez que abras Lamplight.';

  @override
  String importNthOf(Object index, Object total) {
    return '$index de $total';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esperando',
      one: '1 esperando',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'Copiado';

  @override
  String get failureGeneric => 'Eso no ha funcionado.';

  @override
  String get failureNothingLost => 'No se ha perdido nada: prueba otra vez.';

  @override
  String get calendarNothingOnDay => 'nada';

  @override
  String get backupChangeFolder => 'Cambiar la carpeta';

  @override
  String backupSavedTo(String place) {
    return 'Se guarda en $place';
  }

  @override
  String get backupUseDefaultFolder => 'Usar la carpeta habitual';

  @override
  String get backupChooseFolder => 'Elige una carpeta donde guardar las copias';

  @override
  String get folderAndroidRestriction =>
      'Android no permite dar a ninguna aplicación la carpeta Descargas ni todo el almacenamiento interno. Documentos, o una carpeta dentro, sí.';

  @override
  String get folderNotWritable =>
      'No se puede guardar nada en esa carpeta. Prueba con otra.';

  @override
  String get folderRefused => 'No se ha podido usar esa carpeta.';

  @override
  String get folderTryAnother => 'Prueba a elegir otra.';

  @override
  String get aboutHowKept => 'Cómo se guardan tus notas';

  @override
  String get aboutFonts => 'Tipografías y licencias';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutNoBrowser =>
      'Ninguna app de este teléfono puede abrir enlaces.';

  @override
  String get aboutMadeBy => 'Hecho por';

  @override
  String get aboutMadeBySemantic =>
      'Hecho por ProbablyPiyush. Abre LinkedIn en tu navegador.';

  @override
  String get aboutCoffee => 'Invítame a un café';

  @override
  String get aboutCoffeeSemantic =>
      'Invítame a un café. Abre una página en tu navegador.';

  @override
  String get aboutCopyDetails => 'Copiar los detalles';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. Toca para cambiarlo.';
  }

  @override
  String get settingsAddName => 'Pon tu nombre';

  @override
  String get settingsNameOnlyHere => 'Solo en este teléfono';

  @override
  String get settingsNameOptional => 'Opcional. Nunca sale de este teléfono.';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android tiene las notificaciones desactivadas para Lamplight. Puedes activarlas en los ajustes del teléfono, en Aplicaciones.';

  @override
  String get reminderOnceADay => 'Una vez al día';

  @override
  String reminderTodayAt(Object time) {
    return 'hoy a las $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'ayer a las $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return 'el $date a las $time';
  }

  @override
  String get reminderNoneYet => 'Todavía no ha llegado nada';

  @override
  String reminderLastArrived(Object when) {
    return 'La última llegó $when';
  }

  @override
  String reminderNextDue(Object when) {
    return 'La siguiente toca $when';
  }

  @override
  String get aboutHide => 'Ocultar';

  @override
  String get aboutCheckReal => 'Comprueba que este es el Lamplight de verdad';

  @override
  String get entryRevisionsNote => 'Lo que decía antes de que lo cambiaras';

  @override
  String get entryStaysOnDay => 'Sigue estando en este día';

  @override
  String entryDeleteKind(String kind) {
    return 'Borrar $kind';
  }

  @override
  String get shareCouldNotAdd =>
      'Eso no se pudo añadir. Prueba a guardarlo y usar el botón de la foto.';

  @override
  String get openNothingCanOpen =>
      'Nada en este teléfono puede abrir ese tipo de archivo.';

  @override
  String get viewerMore => 'Más';

  @override
  String get docLeavesLamplight => 'Esto sale de Lamplight';

  @override
  String get docKeepItHere => 'Dejarlo aquí';

  @override
  String get docOpenWith => 'Abrir con…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight puede mostrar PDF, imágenes y texto sin dejarlos nunca sin cifrar en tu teléfono. Un archivo $kind necesita otra aplicación: Lamplight puede prestárselo mientras lo lees y recuperarlo después.';
  }

  @override
  String get menuOpenWithNote => 'Otra aplicación, sin dejar copia';

  @override
  String menuSaveKind(String kind) {
    return 'Guardar $kind';
  }

  @override
  String get menuTrashNote => 'Se guarda 30 días y luego desaparece';

  @override
  String get videoBackTen => 'Diez segundos atrás';

  @override
  String get videoForwardTen => 'Diez segundos adelante';

  @override
  String get photoPlayVideo => 'Reproducir este vídeo';

  @override
  String get lockPhraseHint => 'Tus doce palabras, con espacios';

  @override
  String get lockUnlock => 'Abrir';

  @override
  String get errorScreenDidNotOpen =>
      'Esa pantalla no se abrió. No se ha perdido nada.';

  @override
  String get errorGoBack => 'Volver';

  @override
  String recordingCannot(String what) {
    return 'Este teléfono no va a $what una grabación. Se sigue grabando.';
  }

  @override
  String get recordingClose => 'Cerrar';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grabando, $count segundos',
      one: 'Grabando, $count segundo',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => 'Parar y quedarme con esta grabación';

  @override
  String get recordingDiscard => 'Descartar';

  @override
  String get recordingCouldNotStart => 'No se ha podido empezar a grabar.';

  @override
  String get recordingCheckMicrophone =>
      'Comprueba que Lamplight tiene permiso para usar el micrófono.';

  @override
  String get recordingStartAgain => 'volver a empezar';

  @override
  String get recordingCouldNotSave => 'No se ha podido guardar esa grabación.';

  @override
  String get recordingStillHere => 'Sigue aquí: prueba a pararla otra vez.';

  @override
  String get recordingCarryOnSemantic => 'Seguir grabando';

  @override
  String get recordingPauseSemantic => 'Pausar esta grabación';

  @override
  String get recordingCarryOn => 'Seguir';

  @override
  String get recordingPause => 'Pausar';

  @override
  String get sizeAdd => 'Añadir';

  @override
  String get transcribeTitle => 'Escribir lo que se dice';

  @override
  String get transcribeOn =>
      'Las notas de voz se pueden buscar. No se envía nada a ninguna parte.';

  @override
  String get transcribeOff =>
      'Apagado. Las notas de voz solo se encuentran por su día.';

  @override
  String get transcribeLanguage => 'Idioma hablado';

  @override
  String get transcribeLanguageNote =>
      'El idioma en el que hablas en tus grabaciones. Uno a la vez: una frase que cambia de idioma vuelve como la mitad que coincida con este.';

  @override
  String get transcribeNotDownloaded =>
      'Todavía no está descargado en este teléfono; tócalo para bajarlo.';

  @override
  String transcribeGetBetter(String name) {
    return 'Bajar el modelo mejor de $name';
  }

  @override
  String get transcribeGetBetterNote =>
      'Las transcripciones salen bastante más precisas con él. La descarga la hace tu teléfono, no Lamplight, y ocurre una sola vez.';

  @override
  String get transcribeNoLanguages =>
      'Este teléfono aún no ha ofrecido ningún idioma.';

  @override
  String get transcribeNeedsDownloading => 'Hay que descargarlo';

  @override
  String folderStill(String day, String folder) {
    return 'Sigue en $day. También en $folder.';
  }

  @override
  String get folderRenameTitle => 'Cambiar el nombre de la carpeta';

  @override
  String get folderNameHint => 'Una persona, un lugar, una etapa';

  @override
  String get voicePlay => 'Escuchar esta nota de voz';

  @override
  String get voiceForwardThirty => 'Treinta segundos adelante';

  @override
  String voiceSpeed(String speed) {
    return 'Velocidad, ahora $speed veces';
  }

  @override
  String get voiceLengthUnknown =>
      'nota de voz, no se sabe cuánto dura hasta que suena';

  @override
  String get voicePosition => 'Punto de la grabación';

  @override
  String get voiceOpening => 'Abriendo la grabación';

  @override
  String get voiceNoWords => 'No volvió ninguna palabra: prueba otra vez';

  @override
  String get voiceWriteThis => 'Escribir esto';

  @override
  String get voiceCannotWrite =>
      'Este teléfono no puede escribir las notas de voz.';

  @override
  String get voiceLanguageMissing =>
      'Este teléfono todavía no ha descargado ese idioma.';

  @override
  String get voiceWriting => 'Escribiéndolo…';

  @override
  String get voiceWaiting => 'Esperando a que se escriba.';

  @override
  String get voiceWritten => 'Escrito en este teléfono.';

  @override
  String get errorPartNotShown => 'Esta parte no se pudo mostrar.';

  @override
  String get errorScreenShort => 'Esa pantalla no se abrió.';

  @override
  String get errorNothingLost =>
      'No se ha perdido nada. Todo lo que has escrito sigue en la caja fuerte, tal cual estaba.';

  @override
  String get errorHideDetails => 'Ocultar los detalles técnicos';

  @override
  String get errorShowDetails => 'Ver los detalles técnicos';

  @override
  String get errorDetailsNote =>
      'Esto es todo lo que se copiaría. Dice qué falló y en qué parte del código; no contiene nada de lo que hayas escrito.';

  @override
  String get passcodeChangeFailed => 'No se pudo cambiar la contraseña.';

  @override
  String get passcodeOldStillWorks => 'Tu contraseña de antes sigue valiendo.';

  @override
  String get passcodeChanged => 'Contraseña cambiada';

  @override
  String get passcodeWordsUnchanged =>
      'Tus doce palabras no han cambiado, y no necesitas unas nuevas. Abren tu caja fuerte y tus copias de seguridad igual que antes.';

  @override
  String get passcodeOldBackups =>
      'Las copias que ya tienes siguen abriéndose con tu contraseña anterior. Una nueva, hecha ahora, usará la nueva.';

  @override
  String get passcodeMakeBackup => 'Hacer una copia ahora';

  @override
  String get passcodeCurrent => 'Contraseña actual';

  @override
  String get passcodeNewAgain => 'La nueva otra vez';

  @override
  String get passcodeOldBackupsNote =>
      'Las copias de seguridad que ya hiciste seguirán abriéndose con tu contraseña anterior.';

  @override
  String get passcodeWordsNote =>
      'Tus doce palabras de recuperación no cambian y siguen funcionando.';

  @override
  String get licencesFonts =>
      'Todas las tipografías están bajo la SIL Open Font License. No se descarga nada: vienen dentro de la app.';

  @override
  String get licencesSource =>
      'Lamplight es GPL-3.0 con una excepción para tiendas de aplicaciones. El código fuente es la licencia: cualquiera puede leerlo y comprobar que la app hace lo que dice esta pantalla.';

  @override
  String get licencesUnreadable => 'Ese archivo de licencia no se pudo leer.';

  @override
  String get appearanceSample =>
      'Lloviendo toda la tarde. Hice té, leí medio capítulo, olvidé lo que iba a decir y escribí esto.';

  @override
  String get appearanceChromeNote =>
      'Los botones y las etiquetas se quedan así';

  @override
  String get appearanceSizeNote =>
      'Esto va por encima del tamaño de texto de tu propio teléfono, así que si ya lo has subido, esto sube todavía más.';

  @override
  String get voicePause => 'Pausa';

  @override
  String get importIntro =>
      'Si has escrito un diario en otro sitio, Lamplight puede traerlo, siempre que sean archivos de texto con la fecha en el nombre.';

  @override
  String get importHowDates =>
      'Lee archivos de texto y busca una fecha en el nombre —2026-08-24, o 24 agosto 2026— en el nombre del archivo o en las carpetas de encima.';

  @override
  String get importAmbiguousDates =>
      'Las fechas como 03-04-2026 se saltan a propósito. En unos países es el tres de abril y en otros el cuatro de marzo, y adivinar mal colocaría un año de tu vida en los días equivocados sin decírtelo.';

  @override
  String get importFormats =>
      'Lamplight lee texto plano: .txt, .md, .org, .log y otros, incluidos archivos sin extensión. Si tu diario está en otro formato, expórtalo antes como texto.';

  @override
  String get importAtStartOfDay =>
      'Quedarán al principio de cada día, porque el nombre de un archivo da la fecha pero no la hora. Nada de lo que ya hay en Lamplight se cambia ni se borra, y hacer esto dos veces no crea copias.';

  @override
  String get importFileDateNote =>
      'Los pone en el día en que el archivo se modificó por última vez. Si la carpeta se ha copiado entre dispositivos, puede ser el día en que se copió y no el día en que lo escribiste.';

  @override
  String get importSkippedNote =>
      'Estos se saltarán. Se quedan exactamente donde están: no se mueve ni se borra nada de tu carpeta.';

  @override
  String get restoreChooseNote =>
      'Elige tu archivo de copia. Se llamará algo así como Lamplight-2026-08-18.vault.';

  @override
  String get restorePasscodeNote =>
      'Escribe la contraseña de este archivo: la que estaba puesta cuando se hizo la copia.';

  @override
  String get restoreWordsNote =>
      'Escribe las doce palabras, en orden, separadas por espacios.';

  @override
  String get restoreDoNotClose =>
      'No cierres Lamplight hasta que esto termine.';

  @override
  String get exportIntro =>
      'Esto escribe todo lo que hay en Lamplight en una carpeta que tú elijas, como archivos normales: un archivo de texto por día, y cada foto, vídeo, nota de voz y documento con su propio nombre.';

  @override
  String get exportNoLamplightNeeded =>
      'Nada de esa carpeta necesita Lamplight para abrirse. Si esta app deja de funcionar algún día, o dejas de usarla, tus notas se siguen abriendo con cualquier cosa que lea texto.';

  @override
  String get exportWhichOneBody =>
      'Una copia legible sirve para leer, para pasar a otra aplicación, o para conservar algo después de dejar Lamplight. No está protegida.\n\nUn archivo de copia de seguridad sirve para recuperar Lamplight tal como estaba: un teléfono nuevo, o uno que se rompió. Va cerrado con tu contraseña, así que se puede guardar en cualquier sitio, incluida la nube.\n\nCasi todo el mundo quiere la copia de seguridad. Haz también una copia legible si quieres estar seguro de no quedarte nunca atascado.';

  @override
  String get exportNotLockedBody =>
      'No lleva ninguna contraseña. Cualquiera que abra esa carpeta puede leerlo todo. Déjala en un sitio con el que estés a gusto con eso; y si solo quieres algo seguro que guardar, usa mejor Copia de seguridad.';

  @override
  String get backupConfirmNote =>
      'Confirma tu contraseña. Este archivo puede abrirlo todo, así que hacerlo debería ser algo que querías hacer.';

  @override
  String get backupKeepSafeNote =>
      'Tu copia va cerrada con la contraseña que tienes ahora. Guárdala donde te fíes: la nube está bien, porque el archivo es ilegible sin esa contraseña. Nosotros nunca la vemos.';

  @override
  String get backupRestoreWarning =>
      'Abrir una copia sustituye todo lo que hay ahora en Lamplight. Tus notas actuales se apartan hasta comprobar que las restauradas abren.';

  @override
  String get folderWhatItIs =>
      'Una carpeta es un hilo que atraviesa tus días: una persona, un lugar, una etapa.';

  @override
  String get folderNothingMoves =>
      'Nada se traslada a una carpeta. Una anotación se queda en su día y además aparece aquí.';

  @override
  String get folderDeleteNote =>
      'La carpeta desaparece. Todo lo que hay dentro se queda exactamente donde está, en su día.';

  @override
  String get folderNoneInHere =>
      'Aquí todavía no hay nada. Mantén pulsado algo de un día y elige «Añadir a una carpeta».';

  @override
  String get passcodeRuleLength => 'Ocho caracteres o más.';

  @override
  String get passcodeRuleWords =>
      'Unas cuantas palabras normales que recuerdes valen más que una corta con símbolos.';

  @override
  String get passcodeNoMatch => 'Todavía no coinciden.';

  @override
  String get docCopyInClear =>
      'La copia se escribe sin cifrar, así que cualquier app que pueda leer tus archivos podrá leerla. Lo que se queda dentro de Lamplight sigue cifrado igualmente.';

  @override
  String docPageOf(String page, String total) {
    return '$page de $total';
  }

  @override
  String get transcribeTookTooLong =>
      'Esa grabación tardaba demasiado en transcribirse, así que Lamplight ha dejado de esperar. Lo intentará más tarde.';

  @override
  String get transcribeCouldNotWriteDown =>
      'No se ha podido transcribir esa grabación.';

  @override
  String get transcribeRecordingIsSafe =>
      'La grabación en sí está a salvo. Lamplight lo intentará otra vez.';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$at de $total';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · editada';
  }

  @override
  String get docCouldNotOpen => 'No se ha podido abrir ese documento.';

  @override
  String albumThisOne(Object thing) {
    return 'Este $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'Este $thing: $index de $total';
  }

  @override
  String get albumCaptionThese => 'Escribir algo sobre estos';

  @override
  String get albumCaptionThis => 'Escribir algo';

  @override
  String get albumCaptionEdit => 'Cambiar lo escrito';

  @override
  String albumOthersStay(Object count) {
    return 'Los otros $count se quedan. Este va a la papelera durante 30 días.';
  }

  @override
  String get albumGoesToTrash => 'Va a la papelera durante 30 días.';

  @override
  String get photoCouldNotOpen => 'No se ha podido abrir esta imagen.';

  @override
  String get photoMayBeDamaged => 'Puede que esté dañada.';

  @override
  String get docTooBig =>
      'Este es demasiado grande para abrirlo dentro de Lamplight. Puedes guardar una copia y abrirlo en otro sitio.';

  @override
  String docPages(Object count) {
    return '$count páginas';
  }

  @override
  String get docFileEmpty => 'Este archivo está vacío.';

  @override
  String videoTooBig(Object size) {
    return 'Este vídeo es demasiado grande para reproducirlo aquí — $size. No se escribirá sin protección para sortearlo. Guarda una copia para verlo en otro sitio.';
  }

  @override
  String get videoNotAvailableHere =>
      'Esta parte de la app no está disponible en este teléfono.';

  @override
  String get videoCouldNotOpen => 'No se ha podido abrir este vídeo.';

  @override
  String get docGoToPage => 'Ir a una página';

  @override
  String get docGo => 'Ir';

  @override
  String get docPageCouldNotBeDrawn => 'No se ha podido dibujar esta página.';

  @override
  String get passcodeRuleStronger =>
      'Una o dos palabras más lo harían mucho más difícil de adivinar.';

  @override
  String get backupAutoFooter =>
      'Las copias automáticas se hacen al abrir Lamplight, si algo ha cambiado desde la última. Van cerradas con tu contraseña, igual que una que hagas tú.';

  @override
  String get aboutHowKeptBody =>
      'Sin cuenta. Sin servidor. Nada sale de este teléfono.\n\nTus notas van cerradas con tu contraseña, y la llave se hace a partir de ella, así que no hay ninguna copia en ninguna parte, tampoco con nosotros.';

  @override
  String get aboutFree =>
      'Lamplight es gratis y siempre lo será. No hay nada que desbloquear.';

  @override
  String get aboutContact => '¿Algo no va bien? Escríbeme.';

  @override
  String get aboutContactSemantic => 'Enviar comentarios por correo';

  @override
  String aboutNoMail(String address) {
    return 'No hay app de correo en este teléfono. La dirección es $address.';
  }

  @override
  String get backupOnItsOwn => 'Por su cuenta';

  @override
  String get actionDismiss => 'Descartar';

  @override
  String importRange(String from, String to) {
    return 'Del $from al $to.';
  }

  @override
  String get sizeOneCopy =>
      'Lamplight guarda una sola copia. Lo que elijas aquí es lo que tendrás.';

  @override
  String get sizeAddAlways => 'Añadir y no preguntar más';

  @override
  String get trashNothingHere => 'Aquí no hay nada.';

  @override
  String get appearanceAaQuiet => 'Aa\ntranquilo';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se cierra en unos $count segundos.',
      one: 'Se cierra en un segundo.',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => 'Puedes cambiarlo en Bloqueo y seguridad.';

  @override
  String get openingLabel => 'Lamplight se está abriendo';

  @override
  String get recordingNoMic =>
      'Lamplight no puede usar el micrófono. Puedes activarlo en los ajustes del teléfono, en Aplicaciones.';

  @override
  String get recordingPaused => 'En pausa. No se está escuchando nada.';

  @override
  String get videoOpening => 'Abriendo el vídeo…';

  @override
  String albumRemoveThis(String thing) {
    return 'Quitar $thing';
  }

  @override
  String get revisionsNote =>
      'Lo que decía antes de que lo cambiaras. Aquí nada es un botón: puedes seleccionar el texto y copiarlo.';

  @override
  String get composerSemantic => 'Escribe algo para este día';

  @override
  String importStripAdding(String name) {
    return 'Añadiendo $name';
  }

  @override
  String passcodeAtLeast(int count) {
    return 'Al menos $count caracteres';
  }

  @override
  String get searchKindAll => 'Todo';

  @override
  String get searchKindWords => 'Palabras';

  @override
  String get searchKindVoice => 'Voz';

  @override
  String get searchKindPhotos => 'Fotos';

  @override
  String get searchKindFiles => 'Archivos';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Al menos $count caracteres',
      one: 'Al menos 1 carácter',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count días',
      one: 'Queda 1 día',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => 'Se va hoy';

  @override
  String restoreMadeOn(String date) {
    return 'Hecha el $date';
  }

  @override
  String restoreDone(String entries, String days) {
    return 'Restaurado: $entries en $days. Bienvenido de vuelta.';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sin fecha que Lamplight pueda leer',
      one: '1 sin fecha que Lamplight pueda leer',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return 'Anotación de las $time. Toca para editar.';
  }

  @override
  String entrySemanticEdited(String time) {
    return 'Anotación de las $time, editada. Toca para editar.';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when. $body. Toca para ir a ese día.';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$what de las $time. Toca dos veces para abrirlos.';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date, hoy';
  }

  @override
  String get yearGridNothing => 'Nada en este día';

  @override
  String get calendarNothing => 'Nada en este día';

  @override
  String importStripCounted(String name, String counted) {
    return 'Añadiendo $name$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'Cada compilación lleva una firma que solo su autor puede hacer. Esta es la de la copia que tienes. Compárala con la huella publicada junto al código fuente: si coinciden, esta es la app que ese código construye.';

  @override
  String get searchKindVideo => 'Vídeo';

  @override
  String get semanticOn => 'activado';

  @override
  String andMore(int count) {
    return 'y $count más';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anotaciones',
      one: '1 anotación',
      zero: 'nada',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'Hecho';

  @override
  String get checkNotYet => 'Todavía no';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'Usa tu código.';

  @override
  String get searchWordsExample => 'cualquier cosa que hayas escrito';

  @override
  String get searchAFile => 'Un archivo';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'Una carpeta';

  @override
  String get searchFolderExample => 'el nombre que le pusiste';

  @override
  String get searchByFileName => 'por el nombre del archivo';

  @override
  String get searchARecording => 'Una grabación';

  @override
  String get searchAnEntry => 'Una entrada';

  @override
  String get sizeThisOne => 'esto';

  @override
  String get sizeTheseOnes => 'estos';

  @override
  String get passcodeOneMoreCharacter => 'Un carácter más.';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres más: $minimum es el mínimo.',
      one: '1 carácter más: $minimum es el mínimo.',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious =>
      'Eso es de lo primero que probaría cualquiera. Elige otra cosa.';

  @override
  String get passcodeSameCharacter => 'Ese es el mismo carácter repetido.';

  @override
  String get passcodeStraightRun =>
      'Esa es una secuencia seguida de caracteres.';

  @override
  String attachmentLoading(String time) {
    return 'Adjunto a las $time, cargando';
  }

  @override
  String videoSemantic(String time, String length) {
    return 'Vídeo a las $time, $length. Toca dos veces para verlo.';
  }

  @override
  String voiceSemantic(String time, String length) {
    return 'Nota de voz a las $time, $length. Toca dos veces para reproducirla.';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return 'Archivo a las $time, $name, $size. Toca dos veces para abrirlo.';
  }

  @override
  String get lengthUnknown => 'duración desconocida';

  @override
  String get settingsLockNone => 'sin bloqueo automático';

  @override
  String settingsLockAfter(String duration) {
    return 'tras $duration';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'Código, huella, $lock';
  }

  @override
  String get keptNoNetworkTitle => 'Nunca sale de aquí';

  @override
  String get keptNoNetworkBody =>
      'Lamplight no puede usar internet. No es que «no lo haga»: no puede. Android le niega el permiso, y puedes comprobarlo tú mismo en los ajustes de aplicaciones del teléfono en unos treinta segundos.';

  @override
  String get keptPasscodeTitle => 'Tu código es la llave';

  @override
  String get keptPasscodeBody =>
      'La llave que abre tus notas se crea a partir de tu código cada vez que desbloqueas. No se guarda en ningún sitio, así que no hay copia que encontrar, perder ni entregar.';

  @override
  String get keptForgetTitle => 'Si lo olvidas';

  @override
  String get keptForgetBody =>
      'Tus doce palabras son la única otra forma de entrar. Aquí nadie puede restablecer un código, y ese es el mismo hecho que el anterior: una aplicación capaz de dejarte entrar de nuevo también podría dejar entrar a otra persona.';

  @override
  String get keptNothingReadableTitle => 'No queda nada legible por ahí';

  @override
  String get keptNothingReadableBody =>
      'Las fotos, las grabaciones y los archivos se cifran antes de tocar el almacenamiento. Nunca se escribe nada en claro, ni siquiera un instante mientras lo miras.';

  @override
  String get keptLocksItselfTitle => 'Se bloquea solo';

  @override
  String get keptLocksItselfBody =>
      'En cuanto Lamplight pasa a segundo plano, las llaves se destruyen. Las capturas de pantalla están bloqueadas y la aplicación no aparece en la vista de aplicaciones recientes.';

  @override
  String get keptBackUpTitle => 'Haz una copia';

  @override
  String get keptBackUpBody =>
      'Todo está en este teléfono y en ningún otro sitio: esa es la idea y también el riesgo. Una copia de seguridad es un único archivo cifrado que solo abre tu código. Guarda una en algún sitio.';

  @override
  String etaSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan unos $count segundos',
    );
    return '$_temp0';
  }

  @override
  String etaMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan unos $count minutos',
      one: 'Queda un minuto',
    );
    return '$_temp0';
  }

  @override
  String youWroteForMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Escribiste durante $count minutos.',
      one: 'Escribiste durante un minuto.',
    );
    return '$_temp0';
  }
}
