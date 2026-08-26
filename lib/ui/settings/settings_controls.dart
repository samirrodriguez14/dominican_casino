import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

/// Language, sound, and haptic controls shared by login and profile settings.
class AppPreferencesSection extends StatelessWidget {
  const AppPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepo = context.watch<AppRepo>();
    final sounds = context.watch<SoundService>();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel(l10n.language),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SettingsLanguageButton(
                label: 'English',
                selected: appRepo.locale.languageCode == 'en',
                onPressed: () => appRepo.setLocale(const Locale('en')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SettingsLanguageButton(
                label: 'Español',
                selected: appRepo.locale.languageCode == 'es',
                onPressed: () => appRepo.setLocale(const Locale('es')),
              ),
            ),
          ],
        ),
        const SettingsSectionDivider(),
        SettingsSectionLabel(l10n.sound),
        SettingsToggleRow(
          label: l10n.soundEffects,
          value: sounds.sfxEnabled,
          onChanged: sounds.setSfxEnabled,
          volume: sounds.sfxVolume,
          onVolumeChanged: sounds.setSfxVolume,
        ),
        SettingsToggleRow(
          label: l10n.backgroundMusic,
          value: sounds.musicEnabled,
          onChanged: sounds.setMusicEnabled,
          volume: sounds.musicVolume,
          onVolumeChanged: sounds.setMusicVolume,
        ),
        SettingsToggleRow(
          label: l10n.hapticFeedback,
          value: sounds.hapticEnabled,
          onChanged: (enabled) async {
            await sounds.setHapticEnabled(enabled);
            if (enabled) AppHaptics.mediumImpact();
          },
        ),
      ],
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppStyle.theme.caption.copyWith(
        color: AppStyle.theme.textPrimary.withValues(alpha: .72),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

class SettingsSectionDivider extends StatelessWidget {
  const SettingsSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: AppStyle.theme.textPrimary.withValues(alpha: .12),
    );
  }
}

class SettingsLanguageButton extends StatelessWidget {
  const SettingsLanguageButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8),
      minimumSize: Size.zero,
      color: selected
          ? theme.textPrimary.withValues(alpha: .18)
          : theme.textPrimary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
      onPressed: SoundService.wrapTap(onPressed),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? theme.textPrimary
              : theme.textPrimary.withValues(alpha: .7),
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.volume,
    this.onVolumeChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? volume;
  final ValueChanged<double>? onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final hasVolume = volume != null && onVolumeChanged != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          if (hasVolume)
            SizedBox(
              width: 78,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.body.copyWith(fontSize: 13, height: 1.15),
              ),
            )
          else
            Expanded(child: Text(label, style: theme.body)),
          if (hasVolume)
            Expanded(
              child: _CarouselSafeVolumeSlider(
                value: volume!,
                activeColor: theme.success,
                onChanged: onVolumeChanged!,
              ),
            ),
          Transform.scale(
            scale: 0.86,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: theme.success,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Volume slider that works inside [StackedCardCarousel] horizontal swipes.
///
/// Parent carousels own [HorizontalDragGestureRecognizer]s that beat
/// [CupertinoSlider]. We win the arena with an eager recognizer and drive
/// the value ourselves; the Cupertino thumb is display-only.
class _CarouselSafeVolumeSlider extends StatelessWidget {
  const _CarouselSafeVolumeSlider({
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  void _setFromGlobal(BuildContext context, Offset global, double width) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || width <= 0) return;
    final local = box.globalToLocal(global);
    onChanged((local.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _setFromGlobal(context, event.position, width);
          },
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              _EagerHorizontalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _EagerHorizontalDragGestureRecognizer
                  >(
                    _EagerHorizontalDragGestureRecognizer.new,
                    (_EagerHorizontalDragGestureRecognizer instance) {
                      instance.onStart = (details) {
                        _setFromGlobal(context, details.globalPosition, width);
                      };
                      instance.onUpdate = (details) {
                        _setFromGlobal(context, details.globalPosition, width);
                      };
                    },
                  ),
            },
            child: IgnorePointer(
              child: CupertinoSlider(
                value: value,
                min: 0,
                max: 1,
                activeColor: activeColor,
                // Non-null so the control is not drawn disabled.
                onChanged: onChanged,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EagerHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    // Never lose to the parent card carousel.
    acceptGesture(pointer);
  }
}
