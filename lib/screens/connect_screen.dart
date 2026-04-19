import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:usb_serial/usb_serial.dart' as usb;
import '../app_res.dart';
import '../controllers/bluetooth_controller.dart';
import '../controllers/connection_mode_controller.dart';
import '../controllers/usb_controller.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppRes.labelUsbConnectDev)),
      body: Column(
        children: [
          _ModeToggle(),
          Expanded(
            child: Obx(() {
              final ctrl = Get.find<ConnectionModeController>();
              return ctrl.isUsb
                  ? const _UsbPanel()
                  : const _BluetoothPanel();
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mode Toggle
// ─────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ConnectionModeController>();
    return Container(
      color: AppRes.bgSurface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppRes.spaceMD, vertical: AppRes.spaceSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppRes.labelModeToggle,
            style: TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontXS,
              color: AppRes.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppRes.spaceSM),
          Obx(() => Row(
                children: [
                  _ToggleBtn(
                    label: AppRes.modeUsb,
                    active: ctrl.isUsb,
                    onTap: ctrl.switchToUsb,
                  ),
                  const SizedBox(width: AppRes.spaceSM),
                  _ToggleBtn(
                    label: AppRes.modeBluetooth,
                    active: ctrl.isBluetooth,
                    onTap: ctrl.switchToBluetooth,
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppRes.minTouchTarget,
          decoration: BoxDecoration(
            color: active ? AppRes.accentSafe : AppRes.bgPrimary,
            borderRadius: BorderRadius.circular(AppRes.radiusSM),
            border: Border.all(
              color: active ? AppRes.accentSafe : AppRes.borderColor,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontSM,
              fontWeight: FontWeight.bold,
              color: active ? AppRes.bgPrimary : AppRes.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// USB Panel
// ─────────────────────────────────────────────────────────────

class _UsbPanel extends GetView<UsbController> {
  const _UsbPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppRes.spaceMD, vertical: AppRes.spaceSM),
          color: AppRes.bgSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.usb, color: AppRes.accentSafe, size: 18),
                const SizedBox(width: AppRes.spaceSM),
                const Text(AppRes.labelUsbOtg,
                    style: TextStyle(
                      fontFamily: AppRes.fontMono,
                      fontSize: AppRes.fontSM,
                      color: AppRes.textPrimary,
                    )),
              ]),
              const SizedBox(height: AppRes.spaceXS),
              const Text(AppRes.labelUsbBaud,
                  style: TextStyle(
                    fontFamily: AppRes.fontMono,
                    fontSize: AppRes.fontXS,
                    color: AppRes.textSecondary,
                  )),
            ],
          ),
        ),
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
                        borderRadius: BorderRadius.circular(AppRes.radiusSM)),
                  ),
                  child: controller.isScanning.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppRes.bgPrimary))
                      : const Text(AppRes.labelUsbScan,
                          style: TextStyle(
                            fontFamily: AppRes.fontMono,
                            fontSize: AppRes.fontMD,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          )),
                ),
              )),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
                itemCount: controller.devices.length,
                itemBuilder: (_, i) {
                  final usb.UsbDevice dev = controller.devices[i];
                  final isConn = i == controller.connectedIndex.value;
                  final name = dev.productName ?? AppRes.labelUsbDevice;
                  final vid = dev.vid ?? 0;
                  return _DeviceTile(
                    title: name,
                    subtitle:
                        'VID: 0x${vid.toRadixString(16).toUpperCase().padLeft(4, '0')}',
                    badge: controller.chipLabel(vid),
                    isConnected: isConn,
                    connectedLabel: AppRes.labelUsbConnected,
                    connectLabel: AppRes.labelUsbConnect,
                    onConnect: () => controller.connect(i),
                  );
                },
              )),
        ),
        _StatusFooter(textObs: controller.statusText),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bluetooth Panel
// ─────────────────────────────────────────────────────────────

class _BluetoothPanel extends GetView<BluetoothController> {
  const _BluetoothPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // BT enabled check
        StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          builder: (_, snap) {
            final state = snap.data ?? BluetoothAdapterState.unknown;
            if (state != BluetoothAdapterState.on) {
              return _PermissionRow(label: AppRes.labelBtPermission);
            }
            return const SizedBox.shrink();
          },
        ),

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
                        borderRadius: BorderRadius.circular(AppRes.radiusSM)),
                  ),
                  child: controller.isScanning.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppRes.bgPrimary))
                      : const Text(AppRes.labelBtScan,
                          style: TextStyle(
                            fontFamily: AppRes.fontMono,
                            fontSize: AppRes.fontMD,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          )),
                ),
              )),
        ),

        Expanded(
          child: Obx(() => ListView.builder(
                itemCount: controller.devices.length,
                itemBuilder: (_, i) {
                  final ScanResult result = controller.devices[i];
                  final dev = result.device;
                  final isConn =
                      dev.remoteId.str == controller.connectedId.value;
                  final name = dev.platformName.isNotEmpty
                      ? dev.platformName
                      : AppRes.btDeviceName;
                  return _DeviceTile(
                    title: name,
                    subtitle:
                        '${AppRes.labelBtMacAddress}: ${dev.remoteId.str}',
                    badge: result.advertisementData.connectable
                        ? AppRes.labelBtPaired
                        : '',
                    isConnected: isConn,
                    connectedLabel: AppRes.labelBtConnected2,
                    connectLabel: AppRes.labelBtConnect,
                    onConnect: () => controller.connect(dev),
                  );
                },
              )),
        ),

        _StatusFooter(textObs: controller.statusText),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────

class _DeviceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final bool isConnected;
  final String connectedLabel;
  final String connectLabel;
  final VoidCallback onConnect;

  const _DeviceTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isConnected,
    required this.connectedLabel,
    required this.connectLabel,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppRes.spaceMD, vertical: AppRes.spaceXS),
      decoration: BoxDecoration(
        color: AppRes.bgSurface,
        borderRadius: BorderRadius.circular(AppRes.radiusSM),
        border: Border(
          left: BorderSide(
            color: isConnected ? AppRes.accentSafe : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppRes.spaceMD, vertical: AppRes.spaceXS),
        leading: isConnected
            ? const Icon(Icons.lock, color: AppRes.accentSafe, size: 22)
            : const Icon(Icons.device_hub,
                color: AppRes.textSecondary, size: 22),
        title: Text(title,
            style: const TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontMD,
              fontWeight: FontWeight.bold,
              color: AppRes.textPrimary,
            )),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(subtitle,
                  style: const TextStyle(
                    fontFamily: AppRes.fontMono,
                    fontSize: AppRes.fontXS,
                    color: AppRes.textSecondary,
                  )),
            ),
            if (badge.isNotEmpty) ...[
              const SizedBox(width: AppRes.spaceSM),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppRes.spaceXS, vertical: AppRes.badgePadV),
                decoration: BoxDecoration(
                  color: AppRes.accentSafe.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRes.radiusSM),
                ),
                child: Text(badge,
                    style: const TextStyle(
                      fontFamily: AppRes.fontMono,
                      fontSize: AppRes.fontXS,
                      color: AppRes.accentSafe,
                    )),
              ),
            ],
          ],
        ),
        trailing: isConnected
            ? Text(connectedLabel,
                style: const TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontXS,
                  color: AppRes.accentSafe,
                  fontWeight: FontWeight.bold,
                ))
            : OutlinedButton(
                onPressed: onConnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppRes.accentSafe,
                  side: const BorderSide(color: AppRes.accentSafe),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppRes.spaceSM),
                  minimumSize:
                      const Size(AppRes.minTouchTarget, AppRes.minTouchTarget),
                ),
                child: Text(connectLabel,
                    style: const TextStyle(
                      fontFamily: AppRes.fontMono,
                      fontSize: AppRes.fontSM,
                    )),
              ),
      ),
    );
  }
}

class _StatusFooter extends StatelessWidget {
  final RxString textObs;
  const _StatusFooter({required this.textObs});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppRes.spaceMD),
          color: AppRes.bgSurface,
          child: Semantics(
            label: textObs.value,
            child: Text(
              textObs.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppRes.fontMono,
                fontSize: AppRes.fontSM,
                color: AppRes.textSecondary,
              ),
            ),
          ),
        ));
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  const _PermissionRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppRes.spaceMD, vertical: AppRes.spaceSM),
      color: AppRes.accentCaution.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.warning_amber,
              color: AppRes.accentCaution, size: 18),
          const SizedBox(width: AppRes.spaceSM),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontSM,
                  color: AppRes.accentCaution,
                )),
          ),
          OutlinedButton(
            onPressed: () => FlutterBluePlus.turnOn(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppRes.accentCaution,
              side: const BorderSide(color: AppRes.accentCaution),
              padding:
                  const EdgeInsets.symmetric(horizontal: AppRes.spaceSM),
              minimumSize:
                  const Size(AppRes.minTouchTarget, AppRes.minTouchTarget),
            ),
            child: const Text(AppRes.labelGrantAccess,
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontXS,
                )),
          ),
        ],
      ),
    );
  }
}
