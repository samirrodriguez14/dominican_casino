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
  String get playWithFriendHint => isEs
      ? 'Crea una mesa y comparte el ID'
      : 'Create a table and share the ID';
  String get playVsPuli => isEs ? 'Contra Puli' : 'Vs Puli';
  String get playVsPuliHint => isEs
      ? 'Practica contra el bot de la casa'
      : 'Practice against the house bot';
  String get playJoinByIdHint =>
      isEs ? 'Entra el código de un amigo' : 'Enter a code from a friend';
  String joinCostsCoins(int n) => isEs
      ? 'Unirse cuesta $n monedas'
      : 'Joining costs $n coins';
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
  String get confirmPurchase =>
      isEs ? 'Confirmar compra' : 'Confirm purchase';
  String get buy => isEs ? 'Comprar' : 'Buy';
  String get coinsThisGame => isEs ? 'Monedas de la partida' : 'Coins this game';
  String get coinBonuses => isEs ? 'Bonos' : 'Bonuses';
  String get coinWinPot => isEs ? 'Premio' : 'Win pot';
  String get coinsCongratsTitle => isEs ? '¡Felicidades!' : 'Congrats!';
  String coinsCongratsBody(int n) => isEs
      ? 'Ganaste $n monedas'
      : 'You made $n coins';
  String confirmBuyEnergy(int energy, int coins) => isEs
      ? '¿Gastar $coins monedas para obtener $energy de energía?'
      : 'Spend $coins coins to get $energy energy?';
  String confirmBuyCoins(int coins, String price) => isEs
      ? '¿Comprar $coins monedas por $price?'
      : 'Buy $coins coins for $price?';
  String get buyEnergyWithCoins =>
      isEs ? 'Energía por monedas' : 'Energy for coins';
  String get howToPlay => isEs ? 'Cómo jugar' : 'How to play';
  String get tapForInstructions =>
      isEs ? 'Toca para instrucciones' : 'Tap for instructions';
  String get yourTurn => isEs ? 'Tu turno' : 'Your Turn';
  String get opponentTurn => isEs ? 'Turno del rival' : 'Opponent Turn';
  String get settings => isEs ? 'Ajustes' : 'Settings';
  String get store => isEs ? 'Tienda' : 'Store';
  String get games => isEs ? 'Juegos' : 'Games';
  String get profile => isEs ? 'Perfil' : 'Profile';
  String get privacyPolicy =>
      isEs ? 'Política de privacidad' : 'Privacy Policy';
  String get privacy => isEs ? 'Privacidad' : 'Privacy';
  String get instructions => isEs ? 'Instrucciones' : 'Instructions';
  String get welcome => isEs ? 'BIENVENIDO' : 'WELCOME';
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
  String get couldNotLoadGames =>
      isEs ? 'No se pudieron cargar las partidas.' : 'Could not load your games.';
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
  String get owned => isEs ? 'Tuyo' : 'Owned';
  String get locked => isEs ? 'Bloqueado' : 'Locked';
  String get buyEnergy => isEs ? 'Comprar energía' : 'Buy energy';
  String get buyCoins => isEs ? 'Comprar monedas' : 'Buy coins';
  String get energy => isEs ? 'Energía' : 'Energy';
  String get coins => isEs ? 'Monedas' : 'Coins';
  String get energyFull => isEs ? 'Llena' : 'Full';
  String nextEnergyIn(String time) =>
      isEs ? 'Siguiente en $time' : 'Next in $time';
  String get scrollForSettings =>
      isEs ? 'Desliza hacia abajo para ajustes' : 'Scroll down for settings';
  String get scrollForProfile =>
      isEs ? 'Desliza hacia arriba para el perfil' : 'Scroll up for profile';
  String get currentGames => isEs ? 'Actuales' : 'Current';
  String get previousGames => isEs ? 'Anteriores' : 'Previous';
  String get gameHistory => isEs ? 'Historial' : 'History';
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
  String get deleteAccount =>
      isEs ? 'Eliminar datos locales' : 'Delete local data';
  String get deleteAccountBody => isEs
      ? 'Borra tu perfil en este dispositivo y el token de notificaciones. Las partidas en curso pueden quedar huérfanas.'
      : 'Clears your profile on this device and notification token. In-progress matches may be orphaned.';
  String get connectGoogle => isEs ? 'Conectar Google' : 'Connect Google';
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
      ? 'Sales de Google en este dispositivo. Nombre, avatar, tutorial, monedas y energía se restauran al volver a entrar.'
      : 'Signs out of Google on this device. Your name, avatar, tutorial, coins, and energy restore when you sign in again.';
  String get deleteLocalDataGoogleBody => isEs
      ? 'Borra el caché de este dispositivo y cierra sesión. Tu cuenta de Google, nombre, avatar, tutorial, monedas y energía se quedan en la nube.'
      : 'Clears this device\'s cache and signs you out. Your Google account, name, avatar, tutorial, coins, and energy stay in the cloud.';

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
