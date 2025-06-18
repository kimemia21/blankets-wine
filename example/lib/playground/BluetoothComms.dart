// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:io';



// class App extends StatelessWidget {
//   const App({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => BluetoothService(),
//       child: MaterialApp(
//         title: 'Bluetooth Data Share',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           useMaterial3: true,
//           appBarTheme: const AppBarTheme(
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//           ),
//         ),
//         home: const HomeScreen(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }

// class BluetoothService extends ChangeNotifier {
//   BluetoothConnection? _connection;
//   bool _isConnected = false;
//   bool _isScanning = false;
//   bool _isConnecting = false;
//   List<BluetoothDiscoveryResult> _scanResults = [];
//   List<String> _receivedMessages = [];
//   BluetoothDevice? _connectedDevice;

//   // Getters
//   bool get isConnected => _isConnected;
//   bool get isScanning => _isScanning;
//   bool get isConnecting => _isConnecting;
//   List<BluetoothDiscoveryResult> get scanResults => _scanResults;
//   List<String> get receivedMessages => _receivedMessages;
//   BluetoothDevice? get connectedDevice => _connectedDevice;

//   String get connectionStatus {
//     if (_isConnected) {
//       return 'Connected to ${_connectedDevice?.name ?? 'Unknown Device'}';
//     } else if (_isConnecting) {
//       return 'Connecting...';
//     } else if (_isScanning) {
//       return 'Scanning for devices...';
//     } else {
//       return 'Not connected';
//     }
//   }

//   // Initialize Bluetooth
//   Future<bool> initializeBluetooth() async {
//     try {
//       // Request permissions
//       final permissions = await _requestPermissions();
//       if (!permissions) {
//         return false;
//       }

//       // Check if Bluetooth is available
//       final isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
//       if (isAvailable != true) {
//         return false;
//       }

//       // Enable Bluetooth if disabled
//       final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
//       if (isEnabled != true) {
//         await FlutterBluetoothSerial.instance.requestEnable();
//       }

//       return true;
//     } catch (e) {
//       print('Error initializing Bluetooth: $e');
//       return false;
//     }
//   }

//   Future<bool> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       final permissions = [
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetoothAdvertise,
//         Permission.location,
//       ];

//       Map<Permission, PermissionStatus> statuses = await permissions.request();
//       return statuses.values.every((status) => status.isGranted);
//     }
//     return true;
//   }

//   // Start scanning for devices
//   Future<void> startScan() async {
//     if (_isScanning) return;

//     try {
//       _isScanning = true;
//       _scanResults.clear();
//       notifyListeners();

//       FlutterBluetoothSerial.instance
//           .startDiscovery()
//           .listen((result) {
//             _scanResults.add(result);
//             notifyListeners();
//           })
//           .onDone(() {
//             _isScanning = false;
//             notifyListeners();
//           });
//     } catch (e) {
//       print('Error starting scan: $e');
//       _isScanning = false;
//       notifyListeners();
//     }
//   }

//   // Stop scanning
//   Future<void> stopScan() async {
//     try {
//       await FlutterBluetoothSerial.instance.cancelDiscovery();
//       _isScanning = false;
//       notifyListeners();
//     } catch (e) {
//       print('Error stopping scan: $e');
//     }
//   }

//   // Connect to a device
//   Future<bool> connectToDevice(BluetoothDevice device) async {
//     if (_isConnecting || _isConnected) return false;

//     try {
//       _isConnecting = true;
//       _connectedDevice = device;
//       notifyListeners();

//       _connection = await BluetoothConnection.toAddress(device.address);
//       _isConnected = true;
//       _isConnecting = false;

//       // Start listening for incoming data
//       _listenForData();

//       _addMessage('System: Connected to ${device.name}');
//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error connecting to device: $e');
//       _isConnecting = false;
//       _connectedDevice = null;
//       notifyListeners();
//       return false;
//     }
//   }

//   // Listen for incoming data
//   void _listenForData() {
//     _connection?.input
//         ?.listen((Uint8List data) {
//           try {
//             String message = utf8.decode(data);
//             _addMessage('Received: $message');
//           } catch (e) {
//             print('Error decoding received data: $e');
//           }
//         })
//         .onDone(() {
//           _disconnect();
//         });
//   }

//   // Send text message
//   Future<bool> sendMessage(String message) async {
//     if (!_isConnected || _connection == null) return false;

//     try {
//       final data = utf8.encode('$message\n');
//       _connection!.output.add(Uint8List.fromList(data));
//       await _connection!.output.allSent;

//       _addMessage('Sent: $message');
//       return true;
//     } catch (e) {
//       print('Error sending message: $e');
//       return false;
//     }
//   }

//   // Send file data
//   Future<bool> sendFile(List<int> fileData, String fileName) async {
//     if (!_isConnected || _connection == null) return false;

//     try {
//       // Create a file transfer protocol
//       final fileInfo = {
//         'type': 'file',
//         'name': fileName,
//         'size': fileData.length,
//       };

//       // Send file info first
//       final infoData = utf8.encode('FILE_INFO:${json.encode(fileInfo)}\n');
//       _connection!.output.add(Uint8List.fromList(infoData));
//       await _connection!.output.allSent;

//       // Send file data in chunks
//       const chunkSize = 1024;
//       for (int i = 0; i < fileData.length; i += chunkSize) {
//         final end =
//             (i + chunkSize < fileData.length) ? i + chunkSize : fileData.length;
//         final chunk = fileData.sublist(i, end);
//         _connection!.output.add(Uint8List.fromList(chunk));
//         await _connection!.output.allSent;
//       }

//       // Send end marker
//       final endData = utf8.encode('FILE_END\n');
//       _connection!.output.add(Uint8List.fromList(endData));
//       await _connection!.output.allSent;

//       _addMessage('Sent: File - $fileName (${fileData.length} bytes)');
//       return true;
//     } catch (e) {
//       print('Error sending file: $e');
//       return false;
//     }
//   }

//   // Disconnect from device
//   Future<void> disconnect() async {
//     await _disconnect();
//   }

//   Future<void> _disconnect() async {
//     try {
//       await _connection?.close();
//       _connection = null;
//       _isConnected = false;
//       _isConnecting = false;

//       if (_connectedDevice != null) {
//         _addMessage('System: Disconnected from ${_connectedDevice!.name}');
//       }
//       _connectedDevice = null;

//       notifyListeners();
//     } catch (e) {
//       print('Error disconnecting: $e');
//     }
//   }

//   // Make device discoverable
//   Future<void> makeDiscoverable({int timeoutSeconds = 300}) async {
//     try {
//       await FlutterBluetoothSerial.instance.requestDiscoverable(timeoutSeconds);
//     } catch (e) {
//       print('Error making device discoverable: $e');
//     }
//   }

//   // Add message to history
//   void _addMessage(String message) {
//     _receivedMessages.add(message);
//     notifyListeners();
//   }

//   // Clear messages
//   void clearMessages() {
//     _receivedMessages.clear();
//     notifyListeners();
//   }

//   // Get paired devices
//   Future<List<BluetoothDevice>> getPairedDevices() async {
//     try {
//       return await FlutterBluetoothSerial.instance.getBondedDevices();
//     } catch (e) {
//       print('Error getting paired devices: $e');
//       return [];
//     }
//   }

//   @override
//   void dispose() {
//     _disconnect();
//     super.dispose();
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeBluetooth();
//   }

//   Future<void> _initializeBluetooth() async {
//     final bluetoothService = Provider.of<BluetoothService>(
//       context,
//       listen: false,
//     );
//     final success = await bluetoothService.initializeBluetooth();
//     if (!success && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Failed to initialize Bluetooth. Please check permissions and enable Bluetooth.',
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bluetooth Data Share'),
//         centerTitle: true,
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (value) async {
//               final bluetoothService = Provider.of<BluetoothService>(
//                 context,
//                 listen: false,
//               );
//               if (value == 'discoverable') {
//                 await bluetoothService.makeDiscoverable();
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Device is now discoverable')),
//                   );
//                 }
//               }
//             },
//             itemBuilder:
//                 (context) => [
//                   const PopupMenuItem(
//                     value: 'discoverable',
//                     child: Text('Make Discoverable'),
//                   ),
//                 ],
//           ),
//         ],
//       ),
//       body: Consumer<BluetoothService>(
//         builder: (context, bluetoothService, child) {
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Connection Status Card
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       children: [
//                         Icon(
//                           bluetoothService.isConnected
//                               ? Icons.bluetooth_connected
//                               : bluetoothService.isConnecting
//                               ? Icons.bluetooth_searching
//                               : Icons.bluetooth,
//                           size: 48,
//                           color:
//                               bluetoothService.isConnected
//                                   ? Colors.green
//                                   : bluetoothService.isConnecting
//                                   ? Colors.orange
//                                   : Colors.grey,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           bluetoothService.connectionStatus,
//                           textAlign: TextAlign.center,
//                           style: Theme.of(context).textTheme.titleMedium,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Action Buttons
//                 if (!bluetoothService.isConnected) ...[
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed:
//                               bluetoothService.isScanning ||
//                                       bluetoothService.isConnecting
//                                   ? null
//                                   : () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (context) =>
//                                                 const DeviceListScreen(),
//                                       ),
//                                     );
//                                   },
//                           icon: Icon(
//                             bluetoothService.isScanning
//                                 ? Icons.hourglass_empty
//                                 : Icons.search,
//                           ),
//                           label: Text(
//                             bluetoothService.isScanning
//                                 ? 'Scanning...'
//                                 : 'Find Devices',
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder:
//                                     (context) => const PairedDevicesScreen(),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.devices),
//                           label: const Text('Paired'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ] else ...[
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const ChatScreen(),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.chat),
//                           label: const Text('Open Chat'),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: bluetoothService.disconnect,
//                           icon: const Icon(Icons.bluetooth_disabled),
//                           label: const Text('Disconnect'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//                 const SizedBox(height: 16),

//                 // Message History
//                 Expanded(
//                   child: Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Activity Log',
//                                 style: Theme.of(context).textTheme.titleMedium,
//                               ),
//                               if (bluetoothService.receivedMessages.isNotEmpty)
//                                 IconButton(
//                                   onPressed: bluetoothService.clearMessages,
//                                   icon: const Icon(Icons.clear_all),
//                                   tooltip: 'Clear messages',
//                                 ),
//                             ],
//                           ),
//                           const Divider(),
//                           Expanded(
//                             child:
//                                 bluetoothService.receivedMessages.isEmpty
//                                     ? const Center(
//                                       child: Text(
//                                         'No activity yet\nConnect to a device to start',
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(color: Colors.grey),
//                                       ),
//                                     )
//                                     : ListView.builder(
//                                       itemCount:
//                                           bluetoothService
//                                               .receivedMessages
//                                               .length,
//                                       itemBuilder: (context, index) {
//                                         final message =
//                                             bluetoothService
//                                                 .receivedMessages[index];
//                                         final isSystem = message.startsWith(
//                                           'System:',
//                                         );
//                                         final isSent = message.startsWith(
//                                           'Sent:',
//                                         );
//                                         final isReceived = message.startsWith(
//                                           'Received:',
//                                         );

//                                         Color color = Colors.grey;
//                                         IconData icon = Icons.info;

//                                         if (isSystem) {
//                                           color = Colors.blue;
//                                           icon = Icons.info;
//                                         } else if (isSent) {
//                                           color = Colors.green;
//                                           icon = Icons.send;
//                                         } else if (isReceived) {
//                                           color = Colors.orange;
//                                           icon = Icons.inbox;
//                                         }

//                                         return Container(
//                                           margin: const EdgeInsets.symmetric(
//                                             vertical: 2,
//                                           ),
//                                           padding: const EdgeInsets.all(8),
//                                           decoration: BoxDecoration(
//                                             color: color.withOpacity(0.1),
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           child: Row(
//                                             children: [
//                                               Icon(
//                                                 icon,
//                                                 size: 16,
//                                                 color: color,
//                                               ),
//                                               const SizedBox(width: 8),
//                                               Expanded(
//                                                 child: Text(
//                                                   message,
//                                                   style: TextStyle(
//                                                     color: color,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         );
//                                       },
//                                     ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class DeviceListScreen extends StatefulWidget {
//   const DeviceListScreen({super.key});

//   @override
//   State<DeviceListScreen> createState() => _DeviceListScreenState();
// }

// class _DeviceListScreenState extends State<DeviceListScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<BluetoothService>(context, listen: false).startScan();
//     });
//   }

//   @override
//   void dispose() {
//     Provider.of<BluetoothService>(context, listen: false).stopScan();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Available Devices'),
//         actions: [
//           Consumer<BluetoothService>(
//             builder: (context, bluetoothService, child) {
//               return IconButton(
//                 onPressed:
//                     bluetoothService.isScanning
//                         ? bluetoothService.stopScan
//                         : bluetoothService.startScan,
//                 icon: Icon(
//                   bluetoothService.isScanning ? Icons.stop : Icons.refresh,
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<BluetoothService>(
//         builder: (context, bluetoothService, child) {
//           return Column(
//             children: [
//               if (bluetoothService.isScanning) const LinearProgressIndicator(),
//               Expanded(
//                 child:
//                     bluetoothService.scanResults.isEmpty
//                         ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Icon(
//                                 Icons.bluetooth_searching,
//                                 size: 64,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 bluetoothService.isScanning
//                                     ? 'Scanning for devices...'
//                                     : 'No devices found\nTap refresh to scan again',
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         )
//                         : ListView.builder(
//                           itemCount: bluetoothService.scanResults.length,
//                           itemBuilder: (context, index) {
//                             final result = bluetoothService.scanResults[index];
//                             final device = result.device;

//                             return Card(
//                               margin: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 4,
//                               ),
//                               child: ListTile(
//                                 leading: const Icon(Icons.bluetooth),
//                                 title: Text(
//                                   device.name?.isNotEmpty == true
//                                       ? device.name!
//                                       : 'Unknown Device',
//                                 ),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(device.address),
//                                     if (result.rssi != null)
//                                       Text('Signal: ${result.rssi} dBm'),
//                                   ],
//                                 ),
//                                 trailing: ElevatedButton(
//                                   onPressed:
//                                       bluetoothService.isConnecting
//                                           ? null
//                                           : () async {
//                                             final success =
//                                                 await bluetoothService
//                                                     .connectToDevice(device);
//                                             if (success && mounted) {
//                                               Navigator.pop(context);
//                                             } else if (mounted) {
//                                               ScaffoldMessenger.of(
//                                                 context,
//                                               ).showSnackBar(
//                                                 const SnackBar(
//                                                   content: Text(
//                                                     'Failed to connect to device',
//                                                   ),
//                                                 ),
//                                               );
//                                             }
//                                           },
//                                   child: Text(
//                                     bluetoothService.isConnecting
//                                         ? 'Connecting...'
//                                         : 'Connect',
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class PairedDevicesScreen extends StatefulWidget {
//   const PairedDevicesScreen({super.key});

//   @override
//   State<PairedDevicesScreen> createState() => _PairedDevicesScreenState();
// }

// class _PairedDevicesScreenState extends State<PairedDevicesScreen> {
//   List<BluetoothDevice> pairedDevices = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadPairedDevices();
//   }

//   Future<void> _loadPairedDevices() async {
//     final devices =
//         await Provider.of<BluetoothService>(
//           context,
//           listen: false,
//         ).getPairedDevices();
//     setState(() {
//       pairedDevices = devices;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Paired Devices'),
//         actions: [
//           IconButton(
//             onPressed: _loadPairedDevices,
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//       body: Consumer<BluetoothService>(
//         builder: (context, bluetoothService, child) {
//           return pairedDevices.isEmpty
//               ? const Center(
//                 child: Text(
//                   'No paired devices\nPair devices in Android Settings first',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               )
//               : ListView.builder(
//                 itemCount: pairedDevices.length,
//                 itemBuilder: (context, index) {
//                   final device = pairedDevices[index];

//                   return Card(
//                     margin: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 4,
//                     ),
//                     child: ListTile(
//                       leading: const Icon(Icons.bluetooth_connected),
//                       title: Text(device.name ?? 'Unknown Device'),
//                       subtitle: Text(device.address),
//                       trailing: ElevatedButton(
//                         onPressed:
//                             bluetoothService.isConnecting
//                                 ? null
//                                 : () async {
//                                   final success = await bluetoothService
//                                       .connectToDevice(device);
//                                   if (success && mounted) {
//                                     Navigator.pop(context);
//                                   } else if (mounted) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text(
//                                           'Failed to connect to device',
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                         child: Text(
//                           bluetoothService.isConnecting
//                               ? 'Connecting...'
//                               : 'Connect',
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               );
//         },
//       ),
//     );
//   }
// }

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat'),
//         actions: [
//           IconButton(
//             onPressed: () async {
//               // File picker implementation would go here
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('File sharing feature - implementation needed'),
//                 ),
//               );
//             },
//             icon: const Icon(Icons.attach_file),
//             tooltip: 'Send File',
//           ),
//         ],
//       ),
//       body: Consumer<BluetoothService>(
//         builder: (context, bluetoothService, child) {
//           WidgetsBinding.instance.addPostFrameCallback(
//             (_) => _scrollToBottom(),
//           );

//           return Column(
//             children: [
//               // Connection info bar
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 color: Colors.blue.withOpacity(0.1),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.bluetooth_connected, color: Colors.blue),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         bluetoothService.connectedDevice?.name ??
//                             'Unknown Device',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Messages area
//               Expanded(
//                 child:
//                     bluetoothService.receivedMessages
//                             .where(
//                               (msg) =>
//                                   msg.startsWith('Sent:') ||
//                                   msg.startsWith('Received:'),
//                             )
//                             .isEmpty
//                         ? const Center(
//                           child: Text(
//                             'Start a conversation!\nType a message below',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                         )
//                         : ListView.builder(
//                           controller: _scrollController,
//                           padding: const EdgeInsets.all(16),
//                           itemCount:
//                               bluetoothService.receivedMessages
//                                   .where(
//                                     (msg) =>
//                                         msg.startsWith('Sent:') ||
//                                         msg.startsWith('Received:'),
//                                   )
//                                   .length,
//                           itemBuilder: (context, index) {
//                             final messages =
//                                 bluetoothService.receivedMessages
//                                     .where(
//                                       (msg) =>
//                                           msg.startsWith('Sent:') ||
//                                           msg.startsWith('Received:'),
//                                     )
//                                     .toList();
//                             final message = messages[index];
//                             final isSent = message.startsWith('Sent:');
//                             final displayMessage =
//                                 message
//                                     .substring(message.indexOf(':') + 1)
//                                     .trim();

//                             return Align(
//                               alignment:
//                                   isSent
//                                       ? Alignment.centerRight
//                                       : Alignment.centerLeft,
//                               child: Container(
//                                 margin: const EdgeInsets.symmetric(vertical: 4),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 10,
//                                 ),
//                                 constraints: BoxConstraints(
//                                   maxWidth:
//                                       MediaQuery.of(context).size.width * 0.8,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color:
//                                       isSent ? Colors.blue : Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 child: Text(
//                                   displayMessage,
//                                   style: TextStyle(
//                                     color: isSent ? Colors.white : Colors.black,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//               ),

//               // Input area
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       offset: const Offset(0, -2),
//                       blurRadius: 4,
//                       color: Colors.black.withOpacity(0.1),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: const InputDecoration(
//                           hintText: 'Type a message...',
//                           border: OutlineInputBorder(),
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                         ),
//                         onSubmitted:
//                             (text) => _sendMessage(bluetoothService, text),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     FloatingActionButton(
//                       mini: true,
//                       onPressed:
//                           () => _sendMessage(
//                             bluetoothService,
//                             _messageController.text,
//                           ),
//                       child: const Icon(Icons.send),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   void _sendMessage(BluetoothService bluetoothService, String text) {
//     final message = text.trim();
//     if (message.isNotEmpty) {
//       bluetoothService.sendMessage(message);
//       _messageController.clear();
//     }
//   }
// }
