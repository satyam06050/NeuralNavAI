import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/usb_service.dart';

class ArduinoScreen extends StatefulWidget {
  const ArduinoScreen({super.key});

  @override
  State<ArduinoScreen> createState() => _ArduinoScreenState();
}

class _ArduinoScreenState extends State<ArduinoScreen> {
  final UsbService _usbService = Get.find<UsbService>();
  final List<String> _dataLines = [];
  StreamSubscription<List<int>>? _subscription;
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startListening() {
    _subscription = _usbService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          // Convert bytes to string (ASCII)
          String line = String.fromCharCodes(data);
          _dataLines.add(line);

          // Keep only last 500 lines to prevent memory issues
          if (_dataLines.length > 500) {
            _dataLines.removeRange(0, _dataLines.length - 500);
          }
        });

        // Auto-scroll to bottom
        if (_isAutoScroll && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  void _clearData() {
    setState(() {
      _dataLines.clear();
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScroll = !_isAutoScroll;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARDUINO DEBUG'),
        actions: [
          IconButton(
            icon: Icon(
              _isAutoScroll ? Icons.arrow_downward : Icons.remove,
              color: _isAutoScroll ? Colors.green : Colors.grey,
            ),
            onPressed: _toggleAutoScroll,
            tooltip: _isAutoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearData,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _usbService.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _usbService.isConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: TextStyle(
                    color: _usbService.isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_dataLines.length} lines',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          // Data display
          Expanded(
            child: _dataLines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.usb_off_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No data received',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect Arduino to see data',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _dataLines.length,
                    itemBuilder: (context, index) {
                      return _buildDataLine(_dataLines[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataLine(String line) {
    Color textColor = Colors.grey[300]!;

    // Color coding based on content type
    if (line.contains('Angle:')) {
      textColor = Colors.orange[300]!;
    } else if (line.contains('OBJECT') && line.contains('DETECTED')) {
      textColor = Colors.green[300]!;
    } else if (line.contains('SWEEP COMPLETE') ||
        line.contains('Total Objects')) {
      textColor = Colors.blue[300]!;
    } else if (line.startsWith('APP:')) {
      textColor = Colors.purple[300]!;
    } else if (line.contains('DANGER') || line.contains('WARNING')) {
      textColor = Colors.red[300]!;
    } else if (line.contains('---') || line.contains('===')) {
      textColor = Colors.grey[500]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${DateTime.now().toString().split(' ').last.split('.').first}] ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          Expanded(
            child: Text(
              line,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontFamily: 'JetBrainsMono',
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
