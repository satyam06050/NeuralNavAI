import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_res.dart';
import '../controllers/usb_controller.dart';

class UsbScreen extends GetView<UsbController> {
  const UsbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CONNECT DEVICE')),
      body: Column(
        children: [
          // OTG Hint Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppRes.spaceMD, vertical: AppRes.spaceSM),
            color: AppRes.bgSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.usb, color: AppRes.accentSafe, size: 18),
                    const SizedBox(width: AppRes.spaceSM),
                    const Text(
                      AppRes.labelUsbOtg,
                      style: TextStyle(
                        fontFamily: AppRes.fontMono,
                        fontSize: AppRes.fontSM,
                        color: AppRes.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppRes.spaceXS),
                const Text(
                  AppRes.labelUsbBaud,
                  style: TextStyle(
                    fontFamily: AppRes.fontMono,
                    fontSize: AppRes.fontXS,
                    color: AppRes.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Permission Row
          Obx(() => controller.permissionDenied.value
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppRes.spaceMD, vertical: AppRes.spaceSM),
                  color: AppRes.accentCaution.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppRes.accentCaution, size: 18),
                      const SizedBox(width: AppRes.spaceSM),
                      const Expanded(
                        child: Text(
                          AppRes.labelUsbPermission,
                          style: TextStyle(
                            fontFamily: AppRes.fontMono,
                            fontSize: AppRes.fontSM,
                            color: AppRes.accentCaution,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            controller.permissionDenied.value = false,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppRes.accentCaution,
                          side: const BorderSide(color: AppRes.accentCaution),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppRes.spaceSM),
                          minimumSize: const Size(
                              AppRes.minTouchTarget, AppRes.minTouchTarget),
                        ),
                        child: const Text(
                          'GRANT ACCESS',
                          style: TextStyle(
                            fontFamily: AppRes.fontMono,
                            fontSize: AppRes.fontXS,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),

          // Scan Button
          Padding(
            padding: const EdgeInsets.all(AppRes.spaceMD),
            child: Obx(() => SizedBox(
                  width: double.infinity,
                  height: AppRes.minTouchTarget,
                  child: ElevatedButton(
                    onPressed:
                        controller.isScanning.value ? null : controller.scan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppRes.accentSafe,
                      foregroundColor: AppRes.bgPrimary,
                      disabledBackgroundColor:
                          AppRes.accentSafe.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRes.radiusSM)),
                    ),
                    child: controller.isScanning.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppRes.bgPrimary,
                            ),
                          )
                        : const Text(
                            AppRes.labelUsbScan,
                            style: TextStyle(
                              fontFamily: AppRes.fontMono,
                              fontSize: AppRes.fontMD,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                )),
          ),

          // Device List
          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount: controller.devices.length,
                  itemBuilder: (_, i) {
                    final dev = controller.devices[i];
                    final isConnected = i == controller.connectedIndex.value;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppRes.spaceMD, vertical: AppRes.spaceXS),
                      decoration: BoxDecoration(
                        color: AppRes.bgSurface,
                        borderRadius:
                            BorderRadius.circular(AppRes.radiusSM),
                        border: Border(
                          left: BorderSide(
                            color: isConnected
                                ? AppRes.accentSafe
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppRes.spaceMD, vertical: AppRes.spaceXS),
                        leading: isConnected
                            ? const Icon(Icons.lock,
                                color: AppRes.accentSafe, size: 22)
                            : const Icon(Icons.usb,
                                color: AppRes.textSecondary, size: 22),
                        title: Text(
                          dev.name,
                          style: const TextStyle(
                            fontFamily: AppRes.fontMono,
                            fontSize: AppRes.fontMD,
                            fontWeight: FontWeight.bold,
                            color: AppRes.textPrimary,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              'VID: 0x${dev.vid.toRadixString(16).toUpperCase()}',
                              style: const TextStyle(
                                fontFamily: AppRes.fontMono,
                                fontSize: AppRes.fontXS,
                                color: AppRes.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppRes.spaceSM),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppRes.spaceXS,
                                  vertical: 2),
                              decoration: BoxDecoration(
                                color: AppRes.accentSafe.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRes.radiusSM),
                              ),
                              child: Text(
                                controller.chipLabel(dev.vid),
                                style: const TextStyle(
                                  fontFamily: AppRes.fontMono,
                                  fontSize: AppRes.fontXS,
                                  color: AppRes.accentSafe,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: isConnected
                            ? const Text(
                                'CONNECTED',
                                style: TextStyle(
                                  fontFamily: AppRes.fontMono,
                                  fontSize: AppRes.fontXS,
                                  color: AppRes.accentSafe,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () => controller.connect(i),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppRes.accentSafe,
                                  side: const BorderSide(
                                      color: AppRes.accentSafe),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppRes.spaceSM),
                                  minimumSize: const Size(
                                      AppRes.minTouchTarget,
                                      AppRes.minTouchTarget),
                                ),
                                child: const Text(
                                  AppRes.labelUsbConnect,
                                  style: TextStyle(
                                    fontFamily: AppRes.fontMono,
                                    fontSize: AppRes.fontSM,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                )),
          ),

          // Status Footer
          Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppRes.spaceMD),
                color: AppRes.bgSurface,
                child: Semantics(
                  label: controller.statusText.value,
                  child: Text(
                    controller.statusText.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppRes.fontMono,
                      fontSize: AppRes.fontSM,
                      color: AppRes.textSecondary,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
