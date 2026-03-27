import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/usb_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final List<String> dataLines = [];
  StreamSubscription<List<int>>? subscription;
  UsbService? usbService;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UsbService>()) {
      usbService = Get.find<UsbService>();
      subscription = usbService?.dataStream.listen((data) {
        final line = String.fromCharCodes(data);
        if (line.trim().isNotEmpty && mounted) {
          setState(() {
            dataLines.insert(0, line);
            if (dataLines.length > 50) dataLines.removeLast();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arduino Data Test')),
      body: dataLines.isEmpty
          ? const Center(child: Text('No data - Connect Arduino via USB'))
          : ListView.builder(
              itemCount: dataLines.length,
              itemBuilder: (context, index) {
                final line = dataLines[index];
                Color tileColor = Colors.grey[800]!;

                if (line.contains('Angle:')) {
                  tileColor = Colors.orange[900]!;
                } else if (line.contains('OBJECT')) {
                  tileColor = Colors.green[900]!;
                } else if (line.contains('Total Objects')) {
                  tileColor = Colors.blue[900]!;
                }

                return Card(
                  color: tileColor,
                  margin: const EdgeInsets.all(4),
                  child: ListTile(
                    title: Text(
                      line,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Text(
                      '#${index + 1}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
