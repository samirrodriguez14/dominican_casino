import 'package:flutter/cupertino.dart';

/// Minimal bilingual strings (en / es). Prefer Spanish when device locale is es.
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
  String get joinById => isEs ? 'Unirse por ID' : 'Join By Id';
  String get play => isEs ? 'Jugar' : 'Play';
  String get howToPlay => isEs ? 'Cómo jugar' : 'How to play';
  String get yourTurn => isEs ? 'Tu turno' : 'Your Turn';
  String get opponentTurn => isEs ? 'Turno del rival' : 'Opponent Turn';
  String get settings => isEs ? 'Ajustes' : 'Settings';
  String get games => isEs ? 'Juegos' : 'Games';
  String get profile => isEs ? 'Perfil' : 'Profile';
  String get privacyPolicy => isEs ? 'Política de privacidad' : 'Privacy Policy';
  String get chooseTable => isEs ? 'Elige tu mesa' : 'Choose Your Table';
  String get language => isEs ? 'Idioma' : 'Language';
  String get sound => isEs ? 'Sonido' : 'Sound';
  String get soundEffects => isEs ? 'Efectos de sonido' : 'Sound effects';
  String get backgroundMusic => isEs ? 'Música de fondo' : 'Background music';
  String get notifications => isEs ? 'Notificaciones' : 'Notifications';
  String get notificationsOn => isEs ? 'Activadas' : 'On';
  String get notificationsOff => isEs ? 'Desactivadas' : 'Off';
  String get noRealMoney =>
      isEs
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
  String get notificationsRationale =>
      isEs
          ? 'Te avisamos cuando sea tu turno en una partida con amigos.'
          : 'We notify you when it is your turn in a friend match.';
  String get enableNotifications =>
      isEs ? 'Activar notificaciones' : 'Enable notifications';
  String get notNow => isEs ? 'Ahora no' : 'Not now';
  String get deleteAccount =>
      isEs ? 'Eliminar datos locales' : 'Delete local data';
  String get deleteAccountBody =>
      isEs
          ? 'Borra tu perfil en este dispositivo y el token de notificaciones. Las partidas en curso pueden quedar huérfanas.'
          : 'Clears your profile on this device and notification token. In-progress matches may be orphaned.';
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
