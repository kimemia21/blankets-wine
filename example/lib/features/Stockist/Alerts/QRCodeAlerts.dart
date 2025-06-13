import 'package:flutter/material.dart';

class AlertHandler {
  final BuildContext context;
  final bool Function() isMounted;
  final VoidCallback? onStateChanged;

  AlertHandler({
    required this.context,
    required this.isMounted,
    this.onStateChanged,
  });

  void handleSuccess(
    String message, {
    VoidCallback? onSuccess,
    Future<void> Function()? onAsyncSuccess,
  }) async {
    showAlert('Success', message, Colors.green);
    
    if (onSuccess != null) {
      onSuccess();
    }
    
    if (onAsyncSuccess != null) {
      await onAsyncSuccess();
    }
    
    _triggerStateChange();
  }

  void handleError(
    String error, {
    VoidCallback? onError,
  }) {
    showAlert('Error', error, Colors.red);
    
    if (onError != null) {
      onError();
    }
    
    _triggerStateChange();
  }

  void showAlert(String title, String message, Color color) {
    if (!isMounted()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  color.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon with Circle Background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    title == 'Success' ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: color,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title with Better Typography
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message with Outdoor-friendly styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Enhanced Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: color.withOpacity(0.4),
                    ),
                    child: const Text(
                      'GOT IT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerStateChange() {
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }
}

// Usage example:
/*
class YourWidget extends StatefulWidget {
  @override
  _YourWidgetState createState() => _YourWidgetState();
}

class _YourWidgetState extends State<YourWidget> {
  late AlertHandler _alertHandler;
  String _statusMessage = '';
  ScanningService? _service;

  @override
  void initState() {
    super.initState();
    _alertHandler = AlertHandler(
      context: context,
      isMounted: () => mounted,
      onStateChanged: () => setState(() {}),
    );
  }

  void _handleSuccess(String message) async {
    await _alertHandler.handleSuccess(
      message,
      onSuccess: () {
        _statusMessage = message;
      },
      onAsyncSuccess: () async {
        if (_service!.isScanning) {
          await _service!.pauseScanning();
        } else {
          await _service!.resumeScanning();
        }
      },
    );
  }

  void _handleError(String error) {
    _alertHandler.handleError(
      error,
      onError: () {
        _statusMessage = 'Error: $error';
      },
    );
  }
}
*/