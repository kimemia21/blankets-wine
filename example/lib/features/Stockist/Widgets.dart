// void _showAutoDismissingScanResult(String code) {
//   showGeneralDialog(
//     context: context,
//     barrierDismissible: false,
//     barrierColor: Colors.black54,
//     transitionDuration: Duration(milliseconds: 200),
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return AnimatedBuilder(
//         animation: animation,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: animation.value,
//             child: Scaffold(
//               backgroundColor: Colors.transparent,
//               body: Center(
//                 child: Container(
//                   margin: EdgeInsets.all(20),
//                   padding: EdgeInsets.all(40),
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.9,
//                     maxHeight: MediaQuery.of(context).size.height * 0.7,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(color: Colors.green, width: 4),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 20,
//                         spreadRadius: 8,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Large success icon
//                       Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.check_circle,
//                           color: Colors.white,
//                           size: 60,
//                         ),
//                       ),
//                       SizedBox(height: 30),
                      
//                       // Large title
//                       Text(
//                         'ORDER Number SCANNED',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 36,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                           letterSpacing: 2,
//                         ),
//                       ),
//                       SizedBox(height: 40),
                      
//                       // Extra large code display with high contrast
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(30),
//                         decoration: BoxDecoration(
//                           color: Colors.black87,
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: Colors.green, width: 2),
//                         ),
//                         child: Text(
//                           code,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 42,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             fontFamily: 'monospace',
//                             letterSpacing: 4,
//                             height: 1.2,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 30),
                      
//                       // Status with countdown
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           borderRadius: BorderRadius.circular(25),
//                         ),
//                         child: Text(
//                           '✓ SUCCESS - AUTO CLOSING',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 20,
//                             letterSpacing: 1,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );

//   // Auto dismiss after 3 seconds
//   Timer(Duration(seconds: 3), () {
//     if (mounted && Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//       // _processScannedCode(code);
//     }
//   });
// }

// // Auto-dismissing error display
// void _showAutoDismissingError(String error) {
//   showGeneralDialog(
//     context: context,
//     barrierDismissible: false,
//     barrierColor: Colors.black54,
//     transitionDuration: Duration(milliseconds: 200),
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return AnimatedBuilder(
//         animation: animation,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: animation.value,
//             child: Scaffold(
//               backgroundColor: Colors.transparent,
//               body: Center(
//                 child: Container(
//                   margin: EdgeInsets.all(20),
//                   padding: EdgeInsets.all(40),
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.9,
//                     maxHeight: MediaQuery.of(context).size.height * 0.7,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(color: Colors.red, width: 4),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 20,
//                         spreadRadius: 8,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Large error icon
//                       Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.error,
//                           color: Colors.white,
//                           size: 60,
//                         ),
//                       ),
//                       SizedBox(height: 30),
                      
//                       // Large title
//                       Text(
//                         'ORDER ALREADY PROCESSED',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 36,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.red,
//                           letterSpacing: 2,
//                         ),
//                       ),
//                       SizedBox(height: 40),
                      
//                       // Error message display
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(30),
//                         decoration: BoxDecoration(
//                           color: Colors.red[50],
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: Colors.red[300]!, width: 2),
//                         ),
//                         child: Text(
//                           error,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                             height: 1.3,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 30),
                      
//                       // Status with countdown
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.red,
//                           borderRadius: BorderRadius.circular(25),
//                         ),
//                         child: Text(
//                           'ORDER IS ALREADY PROCESSED AND MARKED READY',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 20,
//                             letterSpacing: 1,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );

//   // Auto dismiss after 4 seconds (longer for error to be read)
//   Timer(Duration(seconds: 4), () {
//     if (mounted && Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     }
//   });
// }

// // Alternative: Enhanced SnackBar for less intrusive display
// void _showEnhancedSnackBar(String code) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Container(
//         padding: EdgeInsets.symmetric(vertical: 16),
//         child: Row(
//           children: [
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 color: Colors.green,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.qr_code_scanner,
//                 color: Colors.white,
//                 size: 28,
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'QR CODE SCANNED',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     code,
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       fontFamily: 'monospace',
//                       letterSpacing: 2,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       backgroundColor: Colors.green[700],
//       duration: Duration(seconds: 3),
//       behavior: SnackBarBehavior.floating,
//       margin: EdgeInsets.all(20),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       elevation: 8,
//     ),
//   );
// }