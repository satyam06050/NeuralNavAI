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
  UsbService? usbService;
  StreamSubscription<List<int>>? subscription;
  final StringBuffer _buffer = StringBuffer(); // Buffer for line splitting

  // Connection status tracking
  String _connectionStatus = 'Not connected';
  bool _isConnecting = false;
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UsbService>()) {
      usbService = Get.find<UsbService>();
      subscription = usbService?.dataStream.listen((data) {
        // Accumulate bytes into buffer
        _buffer.write(String.fromCharCodes(data));

        // Split on newlines and process complete lines only
        String buffered = _buffer.toString();
        List<String> lines = buffered.split('\n');

        // Last element may be incomplete — keep it in buffer
        _buffer.clear();
        _buffer.write(lines.last);

        // Process all complete lines (everything except last)
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty && mounted) {
            setState(() {
              dataLines.insert(0, line);
              if (dataLines.length > 50) dataLines.removeLast();
            });
          }
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
      appBar: AppBar(
        title: const Text('Arduino Data Test'),
        actions: [
          // Connection status indicator
          if (_connectionStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _connectionStatus.contains('✅')
                    ? Colors.green.withOpacity(0.2)
                    : _connectionStatus.contains('❌') ||
                          _connectionStatus.contains('Failed')
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isConnecting)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      _connectionStatus.contains('✅')
                          ? Icons.usb
                          : _connectionStatus.contains('❌') ||
                                _connectionStatus.contains('Failed')
                          ? Icons.warning
                          : Icons.usb_off,
                      size: 16,
                      color: _connectionStatus.contains('✅')
                          ? Colors.green
                          : _connectionStatus.contains('❌') ||
                                _connectionStatus.contains('Failed')
                          ? Colors.red
                          : Colors.grey,
                    ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _connectionStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Connect button
          IconButton(
            icon: const Icon(Icons.usb),
            tooltip: 'Connect Arduino',
            onPressed: _isConnecting
                ? null
                : () async {
                    setState(() {
                      _isConnecting = true;
                      _connectionStatus = 'Connecting...';
                      _lastError = '';
                    });

                    if (Get.isRegistered<UsbService>()) {
                      final service = Get.find<UsbService>();
                      bool success = await service.connect();

                      if (!mounted) return;

                      setState(() {
                        _isConnecting = false;
                        if (success) {
                          _connectionStatus = 'Connected ✅';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Arduino Connected!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          _connectionStatus = 'Connection Failed ❌';
                          _lastError =
                              'FTDI FT232R not detected. Check: USB OTG cable, FTDI powered, drivers';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '❌ Connection Failed - Check device & permissions',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      });
                    } else {
                      setState(() {
                        _isConnecting = false;
                        _connectionStatus = 'Service not registered';
                        _lastError = 'UsbService not initialized';
                      });
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Error display area
          if (_lastError.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastError,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Data list
          Expanded(
            child: dataLines.isEmpty
                ? const Center(child: Text('No data - Connect Arduino via USB'))
                : ListView.builder(
                    itemCount: dataLines.length,
                    itemBuilder: (context, index) {
                      final line = dataLines[index];
                      Color tileColor = Colors.grey[800]!;

                      if (line.contains('Angle:')) {
                        tileColor = Colors.orange[900]!;
                      } else if (line.contains('OBJECT') &&
                          line.contains('DETECTED')) {
                        tileColor = Colors.green[900]!;
                      } else if (line.contains('SWEEP COMPLETE') ||
                          line.contains('Total Objects')) {
                        tileColor = Colors.blue[900]!;
                      } else if (line.startsWith('APP:')) {
                        tileColor = Colors
                            .purple[900]!; // Purple for structured APP: lines
                      } else if (line.contains('DANGER')) {
                        tileColor = Colors.red[900]!; // Red for danger alerts
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
          ),
        ],
      ),
    );
  }
}
