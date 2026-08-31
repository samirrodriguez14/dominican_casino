import Flutter
import UIKit
import app_links

/// Forwards scene-based Universal Links / custom schemes to [app_links].
/// Cold starts deliver the URL in [connectionOptions], not AppDelegate launchOptions.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    _forward(urlContexts: connectionOptions.urlContexts)
    for activity in connectionOptions.userActivities {
      _forward(userActivity: activity)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    _forward(urlContexts: URLContexts)
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)
    _forward(userActivity: userActivity)
  }

  private func _forward(urlContexts: Set<UIOpenURLContext>) {
    for context in urlContexts {
      AppLinks.shared.handleLink(url: context.url)
    }
  }

  private func _forward(userActivity: NSUserActivity) {
    if let url = userActivity.webpageURL {
      AppLinks.shared.handleLink(url: url)
    }
  }
}
