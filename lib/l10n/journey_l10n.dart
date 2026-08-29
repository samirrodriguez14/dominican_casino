import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_instruction.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Bilingual Journey story / letter / CTA strings (en / es).
class JourneyL10n {
  const JourneyL10n(this.isEs);

  final bool isEs;

  factory JourneyL10n.of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return JourneyL10n(locale.languageCode == 'es');
  }

  factory JourneyL10n.fromLocale(Locale locale) =>
      JourneyL10n(locale.languageCode == 'es');

  String t(String en, String es) => isEs ? es : en;

  // Speakers
  String get you => t('You', 'Tú');
  String get pulilo => 'Pulilo';
  String get jack => t('Jack', 'Jota');
  String get queen => t('Queen', 'Reina');
  String get king => t('King', 'Rey');
  String get someone => t('Someone', 'Alguien');
  String get someoneElse => t('Someone else', 'Otra persona');
  String get unknown => '???';

  // CTAs
  String get challenge => t('Challenge', 'Desafiar');
  String get continueLabel => t('Continue', 'Continuar');
  String get runAway => t('Run away', 'Huir');
  String get openInstructions =>
      t('Open instructions', 'Abrir instrucciones');
  String get unlockNextChallenger =>
      t('Unlock next challenger', 'Desbloquear siguiente rival');
  String get replay => t('Replay', 'Repetir');
  String get thanks => t('Thanks', 'Gracias');
  String get stayHere => t('Stay here', 'Quedarme');
  String get keepBrowsing => t('Keep browsing', 'Seguir mirando');
  String get returnLabel => t('Return', 'Volver');
  String get sealed => t('Sealed', 'Sellado');
  String get claim => t('Claim', 'Reclamar');
  String get play => t('Play', 'Jugar');
  String get themeUnlocked => t('Theme unlocked', 'Tema desbloqueado');
  String get goToProfile => t('Go to profile', 'Ir al perfil');
  String get unlocked => t('Unlocked', 'Desbloqueado');
  String get newRewardsFromVictory =>
      t('New rewards from your victory.', 'Nuevas recompensas por tu victoria.');
  String avatarReward(JourneyRank rank) =>
      t('${rank.label} avatar', 'Avatar de ${rankLabel(rank)}');
  String aceTrophy(JourneyWorld world) => t(
        '${worldLabel(world)} Ace trophy',
        'Trofeo del As de ${worldLabel(world)}',
      );

  String backToKingdom(String kingdom) =>
      t('Back to $kingdom', 'Volver a $kingdom');

  String enterKingdom(JourneyWorld world) => t(
        'Enter ${worldLabel(world)} kingdom',
        'Entrar al reino de ${worldLabel(world)}',
      );

  String enteringKingdomTitle(JourneyWorld world) => t(
        'Entering ${worldLabel(world)}',
        'Entrando a ${worldLabel(world)}',
      );

  String enteringKingdomBody(JourneyWorld world) => t(
        'You are entering the ${worldLabel(world)} kingdom. '
        'This will change the theme of the application.',
        'Estás entrando al reino de ${worldLabel(world)}. '
        'Esto cambiará el tema de la aplicación.',
      );

  String returnToKingdomTitle(JourneyWorld world) => t(
        'Return to ${worldLabel(world)}?',
        '¿Volver a ${worldLabel(world)}?',
      );

  String returnToKingdomBody(JourneyWorld world) => t(
        'Closing this will take you back to your current progress in the '
        '${worldLabel(world)} kingdom. This will change the theme of the application.',
        'Al cerrar volverás a tu progreso actual en el reino de '
        '${worldLabel(world)}. Esto cambiará el tema de la aplicación.',
      );

  String worldLabel(JourneyWorld world) => switch (world) {
        JourneyWorld.diamonds => t('Diamonds', 'Diamantes'),
        JourneyWorld.clubs => t('Clubs', 'Tréboles'),
        JourneyWorld.hearts => t('Hearts', 'Corazones'),
        JourneyWorld.spades => t('Spades', 'Espadas'),
      };

  String rankLabel(JourneyRank rank) => switch (rank) {
        JourneyRank.jack => jack,
        JourneyRank.queen => queen,
        JourneyRank.king => king,
        JourneyRank.ace => t('Ace', 'As'),
      };

  String cardTitle(JourneyCardDef card) => t(
        '${card.rank.label} of ${card.world.label}',
        '${rankLabel(card.rank)} de ${worldLabel(card.world)}',
      );

  String claimAce(JourneyWorld world) => t(
        'Claim the Ace of ${world.label}.',
        'Reclama el As de ${worldLabel(world)}.',
      );

  String get claimAceCollectHint => t(
        'Collect this Ace and unlock the next world.',
        'Recoge este As y desbloquea el siguiente mundo.',
      );

  String claimTitle(JourneyCardDef card) =>
      t('Claim: ${card.title}', 'Reclamar: ${cardTitle(card)}');

  String replayTitle(JourneyCardDef card) =>
      t('Replay: ${card.title}', 'Repetir: ${cardTitle(card)}');

  String challengeTitle(JourneyCardDef card, {bool clubsCourt = false}) {
    if (clubsCourt) {
      return t('Challenge: Clubs court', 'Desafío: Corte de Tréboles');
    }
    return t('Challenge: ${card.title}', 'Desafío: ${cardTitle(card)}');
  }

  String challengeBody(JourneyCardDef card, {bool clubsCourt = false}) {
    if (clubsCourt) {
      return t(
        'Play Rummy against the King, Queen, and Jack of Clubs.',
        'Juega Rummy contra el Rey, la Reina y la Jota de Tréboles.',
      );
    }
    return t(
      'Play ${card.gameLabel} against this challenger.',
      'Juega ${card.gameLabel} contra este rival.',
    );
  }

  String replayBody(JourneyCardDef card) => t(
        'Play ${card.gameLabel} again against this challenger.',
        'Vuelve a jugar ${card.gameLabel} contra este rival.',
      );

  String get yesIWon => t('Yes — I won.', 'Sí — gané.');

  String get iToldYouNotToLose =>
      t('I told you not to lose.', 'Te dije que no perdieras.');

  String get lossTauntDefault => t(
        'Haha, you didn\'t stand a chance, kiddo. Give me that mask…',
        'Jaja, no tenías ninguna oportunidad, chico. Dame esa máscara…',
      );

  String get replayPraise => t(
        'Good job. It seems you haven\'t lost your touch.',
        'Buen trabajo. Parece que no has perdido la mano.',
      );

  String get spadesJackMustLose => t(
        'Beating me marks you as trouble. You cannot enter the King\'s camp. '
        'Try again — and lose like a refugee.',
        'Ganarme te marca como un problema. No puedes entrar al campamento '
        'del Rey. Inténtalo de nuevo — y pierde como un refugiado.',
      );

  String get defeatedLabel => t('defeated', 'derrotado');

  String worldThemeUnlocked(JourneyWorld world) => t(
        'You unlocked the ${worldLabel(world)} theme.',
        'Desbloqueaste el tema de ${worldLabel(world)}.',
      );

  String worldThemeLabel(JourneyWorld world) =>
      t('${worldLabel(world)} theme', 'Tema de ${worldLabel(world)}');

  /// Localized instruction letters (same ids as English catalog).
  List<JourneyInstruction> get instructions =>
      isEs ? _journeyInstructionsEs : journeyInstructions;

  JourneyInstruction? instructionById(int id) {
    for (final page in instructions) {
      if (page.id == id) return page;
    }
    return null;
  }
}

const List<JourneyInstruction> _journeyInstructionsEs = [
  JourneyInstruction(
    id: 1,
    title: 'Una carta',
    body:
        'La vida es un misterio que se revela a lo largo del camino.\n'
        'Para algunos, ese camino es encontrar el regreso a casa.\n'
        'Si no recuerdas cómo llegar, quizás alguien pueda ayudarte.',
  ),
  JourneyInstruction(
    id: 2,
    title: 'La corte espera',
    body:
        'Tu camino pasa por la corte del Reino de Diamantes. '
        'Se dice que el As de Diamantes guarda respuestas — pero la Jota '
        'se interpone entre tú y el Rey. Enfréntalo cuando estés listo.',
  ),
  JourneyInstruction(
    id: 3,
    title: 'La Reina espera',
    body:
        'La apuesta de la Jota tenía una trampa — la Reina de Diamantes '
        'está frente a ti. Derrótala a las cartas y ella te llevará al Rey. '
        'Sin más trucos.',
  ),
  JourneyInstruction(
    id: 4,
    title: 'La corte del Rey',
    body:
        'La Reina cumple su palabra — casi. Estás ante el Rey de Diamantes. '
        'Él apuesta el As mismo. Derrótalo, y el camino a casa '
        'tal vez se abra.',
  ),
  JourneyInstruction(
    id: 5,
    title: 'El As de Diamantes',
    body:
        'Ganaste la apuesta del Rey. Reclama el As de Diamantes — la carta '
        'más poderosa del mundo.',
  ),
  JourneyInstruction(
    id: 6,
    title: 'El camino de Tréboles',
    body:
        'Escapaste de los guardias. Aquí está la entrada de lo que fue '
        'el reino de Tréboles.\n'
        'Faltan, pero entra y mira qué encuentras. '
        'Recuerda — buscas un lugar donde la paz y la libertad '
        'sean tus aliadas.',
  ),
  JourneyInstruction(
    id: 7,
    title: 'La corte de Tréboles',
    body:
        'La Jota te llevó con su familia — la Reina y el Rey de Tréboles. '
        'Huyeron de un mundo que cambió la virtud por el vicio. Escucha bien; '
        'su apuesta puede abrir el siguiente camino a casa.',
  ),
  JourneyInstruction(
    id: 8,
    title: 'La entrada de Corazones',
    body:
        'Aquí está la entrada del reino de Corazones.\n'
        'Necesitarás un disfraz.\n'
        'Con suerte, con 2 Ases tienes el poder de verte mayor. '
        'Úsalo para ir al reino de Corazones. Encuentra a la Jota y usa lo '
        'que aprendiste para apostar hasta el Rey y hallar el siguiente As.',
  ),
  JourneyInstruction(
    id: 9,
    title: 'La Reina espera',
    body:
        'Felicidades — completaste el desafío de Corazones. '
        'La Reina de Corazones ahora está abierta. Enfréntala después.',
  ),
  JourneyInstruction(
    id: 10,
    title: 'La corte del Rey',
    body:
        'La Reina cae. El Rey pone a prueba a los viajeros con el amor. '
        'Prueba tu amor ante su trono.',
  ),
  JourneyInstruction(
    id: 11,
    title: 'Maestría del Amor',
    body:
        'El Rey es derrotado. Reclama el As de Corazones — '
        'la maestría del amor de este reino.',
  ),
  JourneyInstruction(
    id: 12,
    title: 'La entrada de Espadas',
    body:
        'El Rey te dio su corazón y murió. Debes correr al reino de Espadas '
        'antes de que la Reina se entere.',
  ),
  JourneyInstruction(
    id: 13,
    title: 'Informe de refugiado',
    body:
        'El reino de Espadas ha caído en anarquía. Leales contra rebeldes.\n'
        'Debes convertirte en refugiado e infiltrarte en el campamento del Rey '
        'para obtener su As.\n'
        'Con 3 Ases puedes cambiar tu edad — parecer más joven. Te verás '
        'como un refugiado y te enviarán a demostrar lealtad a la corona con la '
        'Jota de Espadas.\n'
        'El Rey no tendrá las respuestas. La Reina sí.',
  ),
  JourneyInstruction(
    id: 14,
    title: 'Las ruinas',
    body:
        'Tú y el Rey caminan hacia ruinas envueltas en un campo magnético.\n'
        'Dice que el As está oculto debajo — camina hacia el campo y haz lo '
        'que hiciste con los Ases.',
  ),
  JourneyInstruction(
    id: 15,
    title: 'Aguanta más',
    body:
        'Mientras caminas, el campo magnético empieza a debilitarse. El Rey se '
        'levanta y te dice que sigas — pero no puedes. El campo es demasiado poderoso.\n'
        'Él cava la tierra. "¿Dónde está ella? ¿Dónde estás?"\n'
        'Aguanta más… hasta que no puedas más, y el campo magnético '
        'explota y te lanza hacia atrás.',
  ),
  JourneyInstruction(
    id: 16,
    title: 'Continuará',
    body:
        'El cuarto As es tuyo. El campo magnético se rompe — y alguien '
        'que comparte tu viaje ha entrado en la luz.\n'
        'Descansa aquí. El próximo capítulo espera.',
  ),
];
