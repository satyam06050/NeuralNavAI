import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_res.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  static const _headerStyle = TextStyle(
    fontFamily: AppRes.fontMono,
    fontSize: AppRes.fontXS,
    color: AppRes.accentSafe,
    letterSpacing: 2,
    fontWeight: FontWeight.bold,
  );

  static const _labelStyle = TextStyle(
    fontFamily: AppRes.fontMono,
    fontSize: AppRes.fontMD,
    color: AppRes.textPrimary,
  );

  static const _secondaryStyle = TextStyle(
    fontFamily: AppRes.fontMono,
    fontSize: AppRes.fontSM,
    color: AppRes.textSecondary,
  );

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppRes.spaceMD, AppRes.spaceLG, AppRes.spaceMD, AppRes.spaceXS),
        child: Text(title, style: _headerStyle),
      );

  Widget _divider() => const Divider(
        color: AppRes.borderColor,
        height: 1,
        indent: AppRes.spaceMD,
        endIndent: AppRes.spaceMD,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          // ── Voice Settings ──────────────────────────────────────
          _header(AppRes.settingsVoice),
          Obx(() => ListTile(
                title: const Text(AppRes.settingsTtsSpeed, style: _labelStyle),
                subtitle: Text(
                    '${controller.ttsSpeed.value.toStringAsFixed(1)}x',
                    style: _secondaryStyle),
                trailing: SizedBox(
                  width: 180,
                  child: SliderTheme(
                    data: const SliderThemeData(
                      activeTrackColor: AppRes.accentSafe,
                      inactiveTrackColor: AppRes.textSecondary,
                      thumbColor: AppRes.accentSafe,
                    ),
                    child: Slider(
                      value: controller.ttsSpeed.value,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      onChanged: (v) => controller.ttsSpeed.value = v,
                    ),
                  ),
                ),
              )),
          _divider(),
          Obx(() => ListTile(
                title: const Text(AppRes.settingsTtsVolume, style: _labelStyle),
                subtitle: Text(
                    '${(controller.ttsVolume.value * 100).round()}%',
                    style: _secondaryStyle),
                trailing: SizedBox(
                  width: 180,
                  child: SliderTheme(
                    data: const SliderThemeData(
                      activeTrackColor: AppRes.accentSafe,
                      inactiveTrackColor: AppRes.textSecondary,
                      thumbColor: AppRes.accentSafe,
                    ),
                    child: Slider(
                      value: controller.ttsVolume.value,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (v) => controller.ttsVolume.value = v,
                    ),
                  ),
                ),
              )),
          _divider(),
          Obx(() => SwitchListTile(
                title: const Text(AppRes.settingsRepeatMsg, style: _labelStyle),
                value: controller.repeatMsg.value,
                activeThumbColor: AppRes.accentSafe,
                activeTrackColor: AppRes.accentSafe.withValues(alpha: 0.5),
                onChanged: (v) => controller.repeatMsg.value = v,
              )),
          _divider(),
          Obx(() => ListTile(
                title: const Text(AppRes.settingsCooldown, style: _labelStyle),
                trailing: SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: '${controller.cooldown.value}',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: AppRes.fontMono,
                      color: AppRes.textPrimary,
                      fontSize: AppRes.fontMD,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppRes.textSecondary)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppRes.accentSafe)),
                    ),
                    onChanged: (v) => controller.cooldown.value =
                        int.tryParse(v) ?? controller.cooldown.value,
                  ),
                ),
              )),

          // ── Threshold Settings ───────────────────────────────────
          _header(AppRes.settingsThreshold),
          Obx(() => ListTile(
                title: const Text(AppRes.settingsDangerDist, style: _labelStyle),
                subtitle: Text('default: ${AppRes.thresholdDanger}cm',
                    style: _secondaryStyle),
                trailing: SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: '${controller.dangerDist.value}',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: AppRes.fontMono,
                      color: AppRes.accentDanger,
                      fontSize: AppRes.fontMD,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppRes.textSecondary)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppRes.accentDanger)),
                    ),
                    onChanged: (v) => controller.dangerDist.value =
                        int.tryParse(v) ?? controller.dangerDist.value,
                  ),
                ),
              )),
          _divider(),
          Obx(() => ListTile(
                title: const Text(AppRes.settingsCautionDist, style: _labelStyle),
                subtitle: Text('default: ${AppRes.thresholdCaution}cm',
                    style: _secondaryStyle),
                trailing: SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: '${controller.cautionDist.value}',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: AppRes.fontMono,
                      color: AppRes.accentCaution,
                      fontSize: AppRes.fontMD,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppRes.textSecondary)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppRes.accentCaution)),
                    ),
                    onChanged: (v) => controller.cautionDist.value =
                        int.tryParse(v) ?? controller.cautionDist.value,
                  ),
                ),
              )),

          // ── Feedback ─────────────────────────────────────────────
          _header(AppRes.settingsFeedback),
          Obx(() => SwitchListTile(
                title: const Text(AppRes.settingsVibration, style: _labelStyle),
                value: controller.vibration.value,
                activeThumbColor: AppRes.accentSafe,
                activeTrackColor: AppRes.accentSafe.withValues(alpha: 0.5),
                onChanged: (v) => controller.vibration.value = v,
              )),
          _divider(),
          Obx(() => SwitchListTile(
                title: const Text(AppRes.settingsCamera, style: _labelStyle),
                value: controller.camera.value,
                activeThumbColor: AppRes.accentSafe,
                activeTrackColor: AppRes.accentSafe.withValues(alpha: 0.5),
                onChanged: (v) => controller.camera.value = v,
              )),

          // ── About ─────────────────────────────────────────────────
          _header(AppRes.settingsAbout),
          const ListTile(
            title: Text('App version', style: _labelStyle),
            trailing: Text(AppRes.appVersion, style: _secondaryStyle),
          ),
          _divider(),
          const ListTile(
            title: Text(AppRes.appTagline, style: _secondaryStyle),
          ),
          const SizedBox(height: AppRes.spaceXL),
        ],
      ),
    );
  }
}
