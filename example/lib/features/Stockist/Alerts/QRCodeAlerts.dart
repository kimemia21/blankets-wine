import 'package:flutter/material.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';

class QRScanDialog extends StatefulWidget {
  final String orderNumber;
  final VoidCallback onComplete;

  const QRScanDialog({
    Key? key,
    required this.orderNumber,
    required this.onComplete,
  }) : super(key: key);

  @override
  _QRScanDialogState createState() => _QRScanDialogState();
}

class _QRScanDialogState extends State<QRScanDialog> {
  final TextEditingController qrCodeController = TextEditingController();

  @override
  void dispose() {
    qrCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String qrCode = qrCodeController.text.trim();
    
    return AlertDialog(
      backgroundColor: BarPOSTheme.secondaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
      ),
      title: Text(
        'QR Code Input',
        style: TextStyle(
          color: BarPOSTheme.primaryText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQRIcon(),
          SizedBox(height: BarPOSTheme.spacingL),
          _buildOrderNumber(),
          SizedBox(height: BarPOSTheme.spacingM),
          _buildQRInput(),
          SizedBox(height: BarPOSTheme.spacingS),
          _buildValidationWidget(qrCode),
          _buildInstructionText(qrCode),
        ],
      ),
      actions: [
        _buildCancelButton(),
        if (qrCode.isNotEmpty) _buildActionButton(qrCode),
      ],
    );
  }

  Widget _buildQRIcon() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
      ),
      child: Center(
        child: Icon(
          Icons.qr_code_scanner,
          size: 120,
          color: BarPOSTheme.accentDark,
        ),
      ),
    );
  }

  Widget _buildOrderNumber() {
    return Text(
      'Order: ${widget.orderNumber}',
      style: TextStyle(
        color: BarPOSTheme.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildQRInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
        border: Border.all(color: BarPOSTheme.accentDark, width: 1),
      ),
      child: TextField(
        controller: qrCodeController,
        decoration: InputDecoration(
          labelText: 'QR Code',
          labelStyle: TextStyle(color: BarPOSTheme.accentDark),
          hintText: 'Scan QR code to get Order Number',
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(
            Icons.qr_code,
            color: BarPOSTheme.accentDark,
          ),
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        maxLines: 1,
        maxLength: widget.orderNumber.length,
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildValidationWidget(String qrCode) {
    if (qrCode.length != widget.orderNumber.length || qrCode.isEmpty) {
      return SizedBox.shrink();
    }

    bool isMatch = qrCode == widget.orderNumber;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMatch 
            ? BarPOSTheme.successColor.withOpacity(0.1)
            : BarPOSTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
        border: Border.all(
          color: isMatch 
              ? BarPOSTheme.successColor.withOpacity(0.3)
              : BarPOSTheme.errorColor.withOpacity(0.3)
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isMatch ? Icons.check_circle : Icons.error,
                color: isMatch 
                    ? BarPOSTheme.successColor 
                    : BarPOSTheme.errorColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                isMatch ? 'QR Code Match' : 'QR Code Mismatch',
                style: TextStyle(
                  color: isMatch 
                      ? BarPOSTheme.successColor 
                      : BarPOSTheme.errorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isMatch) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expected:', style: TextStyle(color: BarPOSTheme.secondaryText, fontSize: 14)),
                Text(widget.orderNumber, style: TextStyle(color: BarPOSTheme.successColor, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Scanned:', style: TextStyle(color: BarPOSTheme.secondaryText, fontSize: 14)),
                Text(qrCode, style: TextStyle(color: BarPOSTheme.errorColor, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionText(String qrCode) {
    String instruction;
    if (qrCode.length == widget.orderNumber.length && qrCode.isNotEmpty) {
      instruction = qrCode == widget.orderNumber 
          ? 'Ready to complete order' 
          : 'QR code doesn\'t match order';
    } else {
      instruction = 'Enter the QR code details to mark this order as complete';
    }

    return Text(
      instruction,
      style: TextStyle(
        color: BarPOSTheme.secondaryText,
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: Text(
        'Cancel',
        style: TextStyle(
          color: BarPOSTheme.secondaryText,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildActionButton(String qrCode) {
    bool isMatch = qrCode == widget.orderNumber;
    
    return ElevatedButton(
      onPressed: () {
        if (isMatch) {
          Navigator.of(context).pop();
          widget.onComplete();
        } else {
          qrCodeController.clear();
          setState(() {});
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isMatch 
            ? BarPOSTheme.successColor 
            : BarPOSTheme.errorColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        isMatch ? 'Mark Complete' : 'Try Again',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}