import 'package:dominican_casino/models/avatar_catalog.dart';
import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarCatalog', () {
    test('registers all painted ids', () {
      for (final id in AvatarCatalog.paintedIds) {
        final def = AvatarCatalog.byId(id);
        expect(def.id, id);
        expect(def.kind, AvatarKind.painted);
        expect(def.assetPath, isNull);
        expect(def.paintedFallbackId, id);
      }
    });

    test('registers all 16 journey challengers', () {
      expect(AvatarCatalog.journeyAll, hasLength(16));
      for (final world in JourneyWorld.values) {
        for (final rank in JourneyRank.values) {
          final id = journeyAvatarId(world, rank);
          final def = AvatarCatalog.byId(id);
          expect(def.id, id);
          expect(def.isJourney, isTrue);
          expect(def.journeyWorld, world);
          expect(def.journeyRank, rank);
          expect(
            def.assetPath,
            'assets/images/journey/avatars_transparent_challengers/'
            '${world.name}_${rank.name}.png',
          );
        }
      }
    });

    test('unknown id falls back to spade', () {
      final def = AvatarCatalog.byId('not-a-real-avatar');
      expect(def.id, AvatarCatalog.defaultId);
      expect(AvatarCatalog.byId(null).id, AvatarCatalog.defaultId);
      expect(AvatarCatalog.byId('').id, AvatarCatalog.defaultId);
    });

    test('contains only real catalog ids', () {
      expect(AvatarCatalog.contains('palm'), isTrue);
      expect(
        AvatarCatalog.contains(
          journeyAvatarId(JourneyWorld.spades, JourneyRank.ace),
        ),
        isTrue,
      );
      expect(AvatarCatalog.contains(AvatarCatalog.otherHalfId), isTrue);
      expect(AvatarCatalog.contains('journey_nope_jack'), isFalse);
      expect(AvatarCatalog.contains(null), isFalse);
    });

    test('other half is a painted placeholder', () {
      final def = AvatarCatalog.byId(AvatarCatalog.otherHalfId);
      expect(def.kind, AvatarKind.painted);
      expect(def.paintedFallbackId, 'moon');
    });
  });

  group('AvatarLook', () {
    test('resolves catalog asset for journey ids', () {
      final look = AvatarLook.fromId('journey_hearts_queen');
      expect(
        look.resolvedAssetPath,
        'assets/images/journey/avatars_transparent_challengers/hearts_queen.png',
      );
      expect(look.paintedFallbackId, 'heart');
    });

    test('painted ids have no asset', () {
      expect(AvatarLook.fromId('moon').resolvedAssetPath, isNull);
    });

    test('asset override wins', () {
      final look = AvatarLook.fromId(
        'palm',
        assetOverride: 'assets/custom.png',
      );
      expect(look.resolvedAssetPath, 'assets/custom.png');
    });
  });

  group('legacy helpers', () {
    test('journeyAvatarAssetPath delegates to catalog', () {
      expect(
        journeyAvatarAssetPath('journey_hearts_queen'),
        'assets/images/journey/avatars_transparent_challengers/hearts_queen.png',
      );
      expect(journeyAvatarAssetPath('palm'), isNull);
      expect(journeyAvatarAssetPath('journey_nope_jack'), isNull);
    });

    test('paintedAvatarIdFor maps journey worlds to suits', () {
      expect(paintedAvatarIdFor('journey_diamonds_king'), 'diamond');
      expect(paintedAvatarIdFor('journey_clubs_ace'), 'club');
      expect(paintedAvatarIdFor('palm'), 'palm');
      expect(paintedAvatarIdFor(null), 'spade');
    });
  });
}
