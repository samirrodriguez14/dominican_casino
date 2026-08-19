import 'package:flutter/cupertino.dart';

/// Minimal bilingual strings (en / es). Default language is English.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('es')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isEs => locale.languageCode == 'es';

  String get appTitle => isEs ? 'Casino Dominicano' : 'Dominican Casino';
  String get joinById => isEs ? 'Unirse por ID' : 'Join by ID';
  String get play => isEs ? 'Jugar' : 'Play';
  String get playHowPrompt =>
      isEs ? '¿Cómo quieres jugar?' : 'How do you want to play?';
  String get playWithFriend => isEs ? 'Con un amigo' : 'With a friend';
  String get playWithFriends => isEs ? 'Con amigo(s)' : 'With friend(s)';
  String get playFriendChip => isEs ? 'Amigo' : 'Friend';
  String get playFriendsChip => isEs ? 'Amigos' : 'Friends';
  String get playWithFriendHint => isEs
      ? 'Crea una mesa y comparte el ID'
      : 'Create a table and share the ID';
  String get playWithFriendsHint => isEs
      ? 'Crea una mesa de 2 a 4 y comparte el ID'
      : 'Create a table for 2–4 and share the ID';
  String get openSeat => isEs ? 'Libre' : 'Open';
  String get playVsPuli => isEs ? 'Contra bots' : 'Vs AI bot';
  String get playPuliChip => isEs ? 'Bots' : 'AI';
  String get playVsPuliHint =>
      isEs ? 'Juega contra la casa' : 'Play against the house AI';
  String get playHowManyPlayers =>
      isEs ? '¿Cuántos jugadores?' : 'How many players?';
  String playersAtTable(int n) => isEs ? '$n jugadores' : '$n players';
  String youPlusBots(int bots) => bots == 1
      ? (isEs ? 'Tú + 1 bot' : 'You + 1 bot')
      : (isEs ? 'Tú + $bots bots' : 'You + $bots bots');
  String get playJoinByIdHint =>
      isEs ? 'Entra el código de un amigo' : 'Enter a code from a friend';
  String joinCostsEnergy(int n) =>
      isEs ? 'Unirse gasta $n de energía' : 'Joining uses $n energy';
  String get matchStake => isEs ? 'Apuesta' : 'Stake';
  String get notEnoughCoins =>
      isEs ? 'No tienes suficientes monedas' : 'Not enough coins';
  String get notEnoughEnergy =>
      isEs ? 'No tienes suficiente energía' : 'Not enough energy';
  String get notEnoughCoinsBody => isEs
      ? 'Consigue monedas ganando partidas o entra a la tienda.'
      : 'Win matches to earn coins, or open the store.';
  String get notEnoughEnergyBody => isEs
      ? 'Espera a que se recargue o cómprala con monedas en la tienda.'
      : 'Wait for it to refill, or buy more with coins in the store.';
  String get goToStore => isEs ? 'Ir a la tienda' : 'Go to store';
  String get confirmPurchase => isEs ? 'Confirmar compra' : 'Confirm purchase';
  String get buy => isEs ? 'Comprar' : 'Buy';
  String get coinsThisGame =>
      isEs ? 'Monedas de la partida' : 'Coins this game';
  String get coinBonuses => isEs ? 'Bonos' : 'Bonuses';
  String get coinWinPot => isEs ? 'Premio' : 'Win pot';
  String coinPayoutPlace(int place) {
    if (place == 1) return isEs ? '1.er lugar' : '1st place';
    if (place == 2) return isEs ? '2.º lugar' : '2nd place';
    if (place == 3) return isEs ? '3.er lugar' : '3rd place';
    if (place == 4) return isEs ? '4.º lugar' : '4th place';
    return coinWinPot;
  }

  String placeShort(int place) {
    if (place == 1) return isEs ? '1.º' : '1st';
    if (place == 2) return isEs ? '2.º' : '2nd';
    if (place == 3) return isEs ? '3.º' : '3rd';
    if (place == 4) return isEs ? '4.º' : '4th';
    return '$place';
  }

  String tablePayoutHint(int players) => players < 3
      ? (isEs ? 'El ganador se lleva el pozo' : 'Winner takes the pot')
      : (isEs ? '75% al 1.º, 25% al 2.º' : '75% to 1st, 25% to 2nd');
  String eachPlayerBets(int n) =>
      isEs ? 'Cada jugador apuesta $n monedas' : 'Each player bets $n coins';
  String potTotal(int n) => isEs ? 'Pozo $n' : 'Pot $n';
  String get coinsCongratsTitle => isEs ? '¡Felicidades!' : 'Congrats!';
  String coinsCongratsBody(int n) =>
      isEs ? 'Ganaste $n monedas' : 'You made $n coins';

  String get energyCongratsTitle => isEs ? '¡Felicidades!' : 'Congrats!';
  String energyCongratsBody(int n) =>
      isEs ? 'Ganaste $n de energía' : 'You earned $n energy';
  String confirmBuyEnergy(int energy, int coins) => isEs
      ? '¿Gastar $coins monedas para obtener $energy de energía?'
      : 'Spend $coins coins to get $energy energy?';
  String confirmBuyCoins(int coins, String price) => isEs
      ? '¿Comprar $coins monedas por $price?'
      : 'Buy $coins coins for $price?';
  String get dailyReward => isEs ? 'Recompensa diaria' : 'Daily reward';
  String get dailyChallenges => isEs ? 'Desafíos diarios' : 'Daily challenges';
  String get free => isEs ? 'Gratis' : 'Free';
  String get comeBackTomorrow =>
      isEs ? 'Vuelve mañana' : 'Come back tomorrow';

  String comeBackInHours(int hours) =>
      isEs ? 'Vuelve en $hours h' : 'Come back in $hours h';

  String comeBackInMinutes(int minutes) =>
      isEs ? 'Vuelve en $minutes min' : 'Come back in $minutes min';
  String get dailyLoginCaption => isEs ? 'Entrar' : 'Login';
  String get dailyChallengeTydCaption => 'Tres y Dos';
  String get dailyChallengeCasinoCaption => isEs ? 'Casino clásico' : 'Classic Casino';
  String get dailyChallengeTydHint => isEs
      ? 'Gana 3 rondas de Tres y Dos'
      : 'Win 3 Tres y Dos rounds';
  String get dailyChallengeCasinoHint => isEs
      ? 'Gana una partida de Casino clásico'
      : 'Win a classic Casino match';
  String get googleRequiredForDailyTitle =>
      isEs ? 'Entra con Google' : 'Sign in with Google';
  String get googleRequiredForDailyBody => isEs
      ? 'Conecta Google para reclamar recompensas y desafíos diarios.'
      : 'Connect Google to claim daily rewards and challenges.';
  String get debugResetDailyReward => isEs
      ? 'Mantén pulsado para probar de nuevo (debug).'
      : 'Long-press to claim again (debug).';
  String get debugTestEnergyPush => isEs
      ? 'Probar aviso de energía'
      : 'Test energy notification';
  String get buyEnergyWithCoins =>
      isEs ? 'Energía por monedas' : 'Energy for coins';
  String get howToPlay => isEs ? 'Cómo jugar' : 'How to play';
  String get tapForInstructions =>
      isEs ? 'Toca para instrucciones' : 'Tap for instructions';
  String get yourTurn => isEs ? 'Tu turno' : 'Your Turn';
  String get opponentTurn => isEs ? 'Turno del rival' : 'Opponent Turn';
  String get actionStart => isEs ? 'Empezar' : 'Start';
  String get startGame => isEs ? 'Empezar partida' : 'Start game';
  String get actionShare => isEs ? 'Compartir' : 'Share';
  String get actionDeal => isEs ? 'Repartir' : 'Deal';
  String get actionDealAgain => isEs ? 'Repartir de nuevo' : 'Deal again';
  String get actionReady => isEs ? 'Listo' : 'Ready';
  String get actionWaiting => isEs ? 'Esperando' : 'Waiting';
  String get actionShuffle => isEs ? 'Barajar' : 'Shuffle';
  String get actionSkip => isEs ? 'Saltar' : 'Skip';
  String get actionLeave => isEs ? 'Salir' : 'Leave';
  String get settings => isEs ? 'Ajustes' : 'Settings';
  String get store => isEs ? 'Tienda' : 'Store';
  String get games => isEs ? 'Juegos' : 'Games';
  String get profile => isEs ? 'Perfil' : 'Profile';
  String get privacyPolicy =>
      isEs ? 'Política de privacidad' : 'Privacy Policy';
  String get privacy => isEs ? 'Privacidad' : 'Privacy';
  String get instructions => isEs ? 'Instrucciones' : 'Instructions';
  String get welcome => isEs ? 'BIENVENIDO' : 'WELCOME';
  String get clickToPlayQuickMatch =>
      isEs ? 'Toca para una partida rápida' : 'Click to play a quick match';
  String get appByline =>
      isEs ? 'Casino Dominicano por SR2' : 'Dominican Casino by SR2';
  String get theApp => isEs ? 'LA APP' : 'THE APP';
  String get aboutHeadline => isEs
      ? '¡Juega tus juegos de naipes favoritos!'
      : 'Play your favorite card games!';
  String get aboutFeatureGames => isEs
      ? 'Único Casino Dominicano, Tres y Dos y más'
      : 'Unique Dominican Casino, Tres y Dos, and more';
  String get aboutFeaturePlay => isEs
      ? 'Juega contra amigos o nuestros bots'
      : 'Play against friends or our AI bots';
  String get yourName => isEs ? 'Tu nombre' : 'Your name';
  String get editName => isEs ? 'Editar nombre' : 'Edit name';
  String get enterYourName => isEs ? 'Escribe tu nombre' : 'Enter your name';
  String get save => isEs ? 'Guardar' : 'Save';
  String get chooseAvatar => isEs ? 'Elige un avatar' : 'Choose an avatar';
  String get guest => isEs ? 'Invitado' : 'Guest';
  String get google => 'Google';
  String get continueLabel => isEs ? 'Continuar' : 'Continue';
  String get back => isEs ? 'Atrás' : 'Back';
  String get couldNotStart =>
      isEs ? 'No se pudo iniciar la app' : 'Could not start the app';
  String get couldNotStartGame =>
      isEs ? 'No se pudo empezar la partida' : 'Could not start the game';
  String get couldNotLoadGames => isEs
      ? 'No se pudieron cargar las partidas.'
      : 'Could not load your games.';
  String get tryAgain => isEs ? 'Inténtalo de nuevo.' : 'Please try again.';
  String get retry => isEs ? 'Reintentar' : 'Retry';
  String get welcomeTitle =>
      isEs ? 'Bienvenido a Casino Dominicano' : 'Welcome to Dominican Casino';
  String get welcomeTutorialBody => isEs
      ? 'Aprende a jugar con un tutorial rápido contra Puli, nuestro bot.'
      : 'Learn how to play with a short tutorial against Puli, our AI opponent.';
  String get startTutorial => isEs ? 'Empezar tutorial' : 'Start tutorial';
  String get tapAnywhereToExit =>
      isEs ? 'Toca en cualquier lugar para salir' : 'Tap anywhere to exit';
  String get later => isEs ? 'Más tarde' : 'Later';
  String get saveProgressTitle =>
      isEs ? 'Guarda tu progreso' : 'Save your progress';
  String get saveProgressBody => isEs
      ? 'Elige un nombre. Conecta Google si quieres guardar esta cuenta.'
      : 'Pick a name. Connect Google if you want to keep this account.';
  String get saveProgressGoogleBody => isEs
      ? 'Conecta Google si quieres guardar esta cuenta en otros dispositivos.'
      : 'Connect Google if you want to keep this account on other devices.';
  String get chooseTable => isEs ? 'Elige tu mesa' : 'Choose Your Table';
  String get themes => isEs ? 'Temas' : 'Themes';
  String get done => isEs ? 'Listo' : 'Done';
  String get useTable => isEs ? 'Usar' : 'Use';
  String get beatPuli => isEs ? 'Vence a Puli' : 'Beat Puli';
  String confirmBuyPack(String name, int coins) => isEs
      ? '¿Gastar $coins monedas para desbloquear $name?'
      : 'Spend $coins coins to unlock $name?';
  String get cardFaceClassic => isEs ? 'Clásico' : 'Classic';
  String get cardFacePlain => isEs ? 'Liso' : 'Plain';
  String get cardFaceShow => isEs ? 'Marca' : 'Show';
  String get cardMarkNone => isEs ? 'Nada' : 'None';
  String get cardMarkLogo => isEs ? 'Logo' : 'Logo';
  String get cardMarkAvatar => isEs ? 'Avatar' : 'Avatar';
  String get owned => isEs ? 'Tuyo' : 'Owned';
  String get locked => isEs ? 'Bloqueado' : 'Locked';
  String get buyEnergy => isEs ? 'Comprar energía' : 'Buy energy';
  String get buyCoins => isEs ? 'Comprar monedas' : 'Buy coins';
  String get energy => isEs ? 'Energía' : 'Energy';
  String get coins => isEs ? 'Monedas' : 'Coins';
  String get energyFull => isEs ? 'Llena' : 'Full';
  String nextEnergyIn(String time) =>
      isEs ? 'Siguiente en $time' : 'Next in $time';
  String get slideForSettings =>
      isEs ? 'Desliza para ajustes' : 'Slide for settings';
  String get slideForProfile =>
      isEs ? 'Desliza para el perfil' : 'Slide for profile';
  String get currentGames => isEs ? 'Actuales' : 'Current';
  String get previousGames => isEs ? 'Anteriores' : 'Previous';
  String get gameHistory => isEs ? 'Historial' : 'History';
  String get loadMore => isEs ? 'Cargar más' : 'Load more';
  String get noCurrentGames =>
      isEs ? 'No hay partidas actuales' : 'No current games';
  String get noPreviousGames =>
      isEs ? 'No hay partidas anteriores' : 'No previous games';
  String get won => isEs ? 'Ganaste' : 'Won';
  String get lost => isEs ? 'Perdiste' : 'Lost';

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 45) return isEs ? 'ahora' : 'just now';
    if (diff.inMinutes < 60) {
      final n = diff.inMinutes.clamp(1, 59);
      return isEs ? 'hace $n min' : '$n min ago';
    }
    if (diff.inHours < 24) {
      final n = diff.inHours;
      if (isEs) return n == 1 ? 'hace 1 h' : 'hace $n h';
      return n == 1 ? '1 hr ago' : '$n hr ago';
    }
    if (diff.inDays < 7) {
      final n = diff.inDays;
      if (isEs) return n == 1 ? 'hace 1 día' : 'hace $n días';
      return n == 1 ? '1 day ago' : '$n days ago';
    }
    if (diff.inDays < 30) {
      final n = (diff.inDays / 7).floor().clamp(1, 4);
      if (isEs) return n == 1 ? 'hace 1 sem' : 'hace $n sem';
      return n == 1 ? '1 wk ago' : '$n wk ago';
    }
    if (diff.inDays < 365) {
      final n = (diff.inDays / 30).floor().clamp(1, 11);
      if (isEs) return n == 1 ? 'hace 1 mes' : 'hace $n meses';
      return n == 1 ? '1 mo ago' : '$n mo ago';
    }
    final n = (diff.inDays / 365).floor().clamp(1, 99);
    if (isEs) return n == 1 ? 'hace 1 año' : 'hace $n años';
    return n == 1 ? '1 yr ago' : '$n yr ago';
  }

  String get language => isEs ? 'Idioma' : 'Language';
  String get sound => isEs ? 'Sonido' : 'Sound';
  String get soundEffects => isEs ? 'Efectos de sonido' : 'Sound effects';
  String get backgroundMusic => isEs ? 'Música de fondo' : 'Background music';
  String get hapticFeedback => isEs ? 'Háptica' : 'Haptics';
  String get notifications => isEs ? 'Notificaciones' : 'Notifications';
  String get notificationsOn => isEs ? 'Activadas' : 'On';
  String get notificationsOff => isEs ? 'Desactivadas' : 'Off';
  String get noRealMoney => isEs
      ? 'Este juego no usa dinero real. Las fichas son solo puntos de partida.'
      : 'This game does not use real money. Chips are match points only.';
  String get comingSoon => isEs ? 'Próximamente…' : 'Coming soon…';
  String get skipTutorial => isEs ? 'Saltar' : 'Skip';
  String get skipTutorialTitle =>
      isEs ? '¿Saltar el tutorial?' : 'Skip tutorial?';
  String get skipTutorialBody => isEs
      ? 'Sigue en el tutorial, ve al inicio o empieza una partida contra Puli.'
      : 'Stay in the tutorial, head home, or start a real game against Puli.';
  String get tutorialGotIt => isEs ? 'Ok' : 'Got it';
  String get tutorialWelcome => isEs
      ? '¡Vamos! Junta cartas para capturarlas.'
      : "Let's go! Match cards to capture them.";
  String get tutorialTapFive => isEs ? 'Toca tu 5♦.' : 'Tap your 5♦.';
  String get tutorialTapThree => isEs ? 'Ahora toca el 3♥.' : 'Now tap the 3♥.';
  String get tutorialPressAdd =>
      isEs ? 'Toca Añadir para juntarlas.' : 'Tap Add to stack them.';
  String get tutorialPuliTookNine => isEs
      ? 'Puli se llevó el 9. Tu montón sigue ahí.'
      : 'Puli took the 9. Your stack is still there.';
  String get tutorialTapEight => isEs ? 'Toca tu 8♠.' : 'Tap your 8♠.';
  String get tutorialTapStackEight =>
      isEs ? 'Toca el montón de 8.' : 'Tap the stack of 8.';
  String get tutorialPressTake =>
      isEs ? 'Toca Tomar para quedártelo.' : 'Tap Take Stack to keep it.';
  String get tutorialPuliPlayedTwo => isEs
      ? 'Puli jugó un 2 junto al J. Eso suma 13.'
      : 'Puli played a 2 next to the Jack. That\'s 13.';
  String get tutorialTapJackAndTwo =>
      isEs ? 'Toca el J♣ y el 2♥.' : 'Tap the J♣ and the 2♥.';
  String get tutorialPressAddShort => isEs ? 'Toca Añadir.' : 'Tap Add.';
  String get tutorialTapKing =>
      isEs ? 'Toca tu Rey — también vale 13.' : 'Tap your King — it\'s also 13.';
  String get tutorialTapStack => isEs ? 'Toca el montón.' : 'Tap the stack.';
  String get tutorialPressTakeShort => isEs ? 'Toca Tomar.' : 'Tap Take Stack.';
  String get tutorialSweep => isEs
      ? '¡Mesa vacía — un virao!'
      : 'Empty table — that\'s a sweep (virao)!';
  String get tutorialReady => isEs
      ? '¡Listo! ¿Juegas una de verdad?'
      : 'You\'re ready. Play a real game?';
  String get stay => isEs ? 'Quedarse' : 'Stay';
  String get home => isEs ? 'Inicio' : 'Home';
  String get next => isEs ? 'Siguiente' : 'Next';
  String get friend => isEs ? 'Amigo' : 'Friend';
  String get aiBot => isEs ? 'Puli (bot)' : 'Puli (AI bot)';
  String get startNewGame =>
      isEs ? 'Nueva partida contra' : 'Start New Game Against';
  String get joinGame => isEs ? 'Unirse a partida' : 'Join Game';
  String get enterGameId => isEs ? 'ID de la partida' : 'Enter Game ID';
  String get cancel => isEs ? 'Cancelar' : 'Cancel';
  String get join => isEs ? 'Unirse' : 'Join';
  String get notificationsRationale => isEs
      ? 'Te avisamos cuando sea tu turno en una partida con amigos.'
      : 'We notify you when it is your turn in a friend match.';
  String get enableNotifications =>
      isEs ? 'Activar notificaciones' : 'Enable notifications';
  String get notNow => isEs ? 'Ahora no' : 'Not now';
  String get deleteAccount => isEs ? 'Eliminar cuenta' : 'Delete account';
  String get deleteAccountBody => isEs
      ? 'Esto elimina tu cuenta de forma permanente. Si solo quieres borrar los datos de este dispositivo, cierra sesión.'
      : 'This permanently deletes your account. To only clear this device, log out instead.';
  String get deleteLocalData => isEs ? 'Eliminar datos' : 'Delete data';
  String get deleteLocalDataBody => isEs
      ? 'Se borrarán los datos de este dispositivo y no se podrán recuperar.'
      : 'Data on this device will be removed and cannot be recovered.';
  String get deleteAccountFailed => isEs
      ? 'No se pudo eliminar la cuenta. Inténtalo de nuevo.'
      : 'Couldn\'t delete the account. Please try again.';
  String get deletingAccount =>
      isEs ? 'Eliminando cuenta…' : 'Deleting account…';
  String get deletingLocalData =>
      isEs ? 'Eliminando datos…' : 'Removing data…';
  String get connectGoogle => isEs ? 'Conectar Google' : 'Connect Google';
  String get connectGoogleWarning => isEs
      ? 'Si esta cuenta de Google ya tiene progreso, reemplazará lo de este dispositivo. El progreso local se perderá.'
      : 'If this Google account already has progress, it will replace what\'s on this device. Local progress will be lost.';
  String get googleRequiredForFriendsTitle =>
      isEs ? 'Entra con Google' : 'Sign in with Google';
  String get googleRequiredForFriendsBody => isEs
      ? 'Las partidas con amigos y unirse por ID necesitan una cuenta de Google.'
      : 'Friend matches and join by ID need a Google account.';
  String get googleConnected =>
      isEs ? 'Conectado con Google' : 'Connected with Google';
  String get account => isEs ? 'Cuenta' : 'Account';
  String get logOut => isEs ? 'Cerrar sesión' : 'Log out';
  String get logOutBody => isEs
      ? 'Sales de Google y se borra el progreso de este dispositivo. Nombre, temas, monedas y energía se restauran al volver a entrar.'
      : 'Signs out of Google and clears progress on this device. Your name, themes, coins, and energy restore when you sign in again.';

  String googleSignInError(String? code) {
    switch (code) {
      case 'operation-not-allowed':
        return isEs
            ? 'Google no está disponible todavía.'
            : 'Google sign-in isn\'t available yet.';
      case 'network-request-failed':
        return isEs
            ? 'Sin conexión. Inténtalo de nuevo.'
            : 'No connection. Please try again.';
      case 'clientConfigurationError':
      case 'providerConfigurationError':
        return isEs
            ? 'Google no está configurado en este dispositivo.'
            : 'Google isn\'t configured on this device.';
      default:
        return isEs
            ? 'No se pudo conectar con Google. Inténtalo de nuevo.'
            : 'Couldn\'t connect with Google. Please try again.';
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'es';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
