import 'dart:async';
import 'package:camera/camera.dart' as camera;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraController extends GetxController {
  late camera.CameraController _camera;
  late List<camera.CameraDescription> _cameras;

  final RxBool isInitialized = false.obs;
  final RxBool isStreaming = false.obs;
  final Rxn<camera.CameraDescription> selectedCamera =
      Rxn<camera.CameraDescription>();

  @override
  void onInit() {
    super.onInit();
    requestPermissionAndInitialize();
  }

  Future<void> requestPermissionAndInitialize() async {
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      await initializeCamera();
    } else {
      debugPrint('Camera permission denied');
      isInitialized.value = false;
    }
  }

  Future<void> initializeCamera() async {
    try {
      // Get available cameras
      _cameras = await camera.availableCameras();

      if (_cameras.isNotEmpty) {
        // Select back camera by default, or first available
        selectedCamera.value = _cameras.firstWhere(
          (cam) => cam.lensDirection == camera.CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        await _initializeSelectedCamera();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      isInitialized.value = false;
    }
  }

  Future<void> _initializeSelectedCamera() async {
    if (selectedCamera.value == null) return;

    try {
      _camera = camera.CameraController(
        selectedCamera.value!,
        camera.ResolutionPreset.medium,
      );

      await _camera.initialize();

      isInitialized.value = true;
      update();
    } catch (e) {
      debugPrint('Error initializing selected camera: $e');
      isInitialized.value = false;
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    await _camera.dispose();

    final currentIndex = _cameras.indexOf(selectedCamera.value!);
    final nextIndex = (currentIndex + 1) % _cameras.length;
    selectedCamera.value = _cameras[nextIndex];

    await _initializeSelectedCamera();
  }

  camera.CameraController? get cameraController => _camera;

  @override
  void onClose() {
    _camera.dispose();
    super.onClose();
  }
}
