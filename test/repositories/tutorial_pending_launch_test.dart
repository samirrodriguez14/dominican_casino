import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/tutorial_pending_launch.dart';
import 'package:youareup/repositories/app_repo.dart';
import 'package:youareup/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late AppRepo repo;

  setUp(() {
    repo = AppRepo(fs: MockFirestoreService());
  });

  test('takeTutorialPendingLaunch returns and clears stash', () {
    const launch = TutorialPendingLaunch(
      mode: GameMode.casino,
      local: true,
    );
    repo.setTutorialPendingLaunch(launch);
    expect(repo.tutorialPendingLaunch, launch);

    final taken = repo.takeTutorialPendingLaunch();
    expect(taken, launch);
    expect(repo.tutorialPendingLaunch, isNull);
  });

  test('clearTutorialPendingLaunch drops stash without returning', () {
    repo.setTutorialPendingLaunch(
      const TutorialPendingLaunch(mode: GameMode.rummy, local: false),
    );
    repo.clearTutorialPendingLaunch();
    expect(repo.tutorialPendingLaunch, isNull);
    expect(repo.takeTutorialPendingLaunch(), isNull);
  });
}
