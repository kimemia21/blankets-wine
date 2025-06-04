import 'package:flutter/material.dart';

class SimpleHiddenTextField extends StatefulWidget {
  @override
  _SimpleHiddenTextFieldState createState() => _SimpleHiddenTextFieldState();
}

class _SimpleHiddenTextFieldState extends State<SimpleHiddenTextField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _scannedData = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus the hidden field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Hidden Scanner Input')),
      body: Stack(
        children: [
          // Your main UI
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scanned Data:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  _scannedData.isEmpty ? 'Waiting for scan...': _scannedData,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          // Hidden TextField positioned off-screen
          Positioned(
            left: -1000,
            top: -1000,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              onSubmitted: (value) {
                // This runs when Enter is pressed (barcode scanner sends this)
                setState(() {
                  _scannedData = value;
                });
                _controller.clear(); // Clear for next scan
                _focusNode.requestFocus(); // Keep focus for continuous scanning
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: SimpleHiddenTextField(),
  ));
}