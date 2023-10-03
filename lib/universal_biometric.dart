import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

//import 'package:flutter_to_native/splash_screen.dart';

//main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: FutureBuilder(
//         // Simulate a delay for the splash screen (e.g., 2 seconds)
//         future: Future.delayed(const Duration(seconds: 2), () => true),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             // Display the splash screen while waiting
//             return const SplashScreen();
//           } else {
//             // Navigate to the HomePage when the delay is done
//             return const HomePage();
//           }
//         },
//       ),
//     );
//   }
// }

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get USB Device Info:-'),
      ),
      body: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('flutter.native/helper');
  List<Map<String, String>> _usbDeviceDetailsList = [];
  Map<String, bool> sdkAvailabilityMap = {};
  bool loading = false;
  String pidBlock = "None";
  // String _TAG = "flutter_to_native [fp]:: ";

  // Define a map to associate device names with their respective logo assets
  Map<String, String> deviceLogoAssets = {
    "SAGEM SA": "assets/device_logos/samsung_logo.png",
    "NITGEN USB DEVICE": "assets/device_logos/lg_logo.png",
    "MANTRA": "assets/device_logos/mantra.png",
    "Mvsilicon": "assets/device_logos/Mvsilicon.png",
    "SecuGen Corp.": "assets/device_logos/Secugen.png"
    // Add more device names and logo assets as needed
  };

  String currentLogoAsset =
      "assets/device_logos/default_logo.png"; // Default logo

  // Map to store driver availability and PID data
  Map<String, bool> driverAvailabilityMap = {};
  Map<String, String> pidDataMap = {};

  @override
  void initState() {
    super.initState();
    // Enumerate USB devices initially when the widget is created
    enumerateUsbDevices();
  }

  Future<void> enumerateUsbDevices() async {
    setState(() {
      loading = true; // Show loading screen
    });

    try {
      final List<dynamic> results =
          await platform.invokeMethod('enumerateUsbDevices');
      setState(() {
        _usbDeviceDetailsList = results
            .map((dynamic result) => Map<String, String>.from(result))
            .toList();
        loading = false; // Hide loading screen

        // Determine and set the appropriate logo asset based on the first connected USB device.
        if (_usbDeviceDetailsList.isNotEmpty) {
          String deviceName = _usbDeviceDetailsList[0]['Manufacturer'] ?? '';
          if (deviceLogoAssets.containsKey(deviceName)) {
            currentLogoAsset = deviceLogoAssets[deviceName]!;
          }
        }

        // Initialize the SDK availability map
        for (var device in _usbDeviceDetailsList) {
          String deviceId = device['Device ID'] ?? '';
          sdkAvailabilityMap[deviceId] = isSdkAvailable(device);
        }
      });
      // ignore: unused_catch_clause
    } on PlatformException catch (e) {
      setState(() {
        loading = false; // Hide loading screen
      });
      print("Failed to enumerate USB devices: ${e.message}");
    }
  }

  bool isSdkAvailable(Map<String, String> device) {
    // Add your logic here to check if the SDK is available for the device.
    // You can use the device details to make this determination.
    // Return true if the SDK is available, and false otherwise.
    // Customize this logic according to your requirements.
    return true; // Change this condition based on your requirements.
  }

  Widget devicePackageInfo(Map<String, String> deviceDetails) {
    String deviceStatus = deviceDetails['Device Status'] ?? 'False';

    if (bool.parse(deviceStatus, caseSensitive: false)) {
      return Column(
        children: [
          Text(
            'Package Name: ${deviceDetails['Package Name']}',
            style: const TextStyle(
              fontSize: 16, // Change font size
            ),
          ),
          Text(
            'Package is present: ${deviceDetails['Package Status']}',
            style: const TextStyle(
              fontSize: 16, // Change font size
            ),
          ),
        ],
      );
    } else {
      return const Text(
        'Device is not recognisable',
        style: TextStyle(
          fontSize: 16, // Change font size
        ),
      );
    }
  }

  Future<void> _dialogBuilder(BuildContext context, String title,
      String content, String approveText, Function() functionToRunOnApproved) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(approveText),
              onPressed: () {
                Navigator.of(context).pop();
                functionToRunOnApproved();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> openApp(String? packageName, bool isPresent) async {
    if (packageName == null) return;

    try {
      if (isPresent) {
        await platform.invokeMethod('launchApp', packageName);
      } else {
        await platform.invokeMethod('installApp', packageName);
      }
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  Future<void> captureRDDevice(String? packageName) async {
    if (packageName == null) return;

    try {
      String result =
          await platform.invokeMethod('captureRDDevice', packageName);
      print("fp pidblock : $pidBlock");
      setState(() {
        pidBlock = result;
      });
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white12,
      child: Center(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            ElevatedButton(
              onPressed: enumerateUsbDevices,
              child: const Text('Get USB Device Information'),
            ),
            if (loading)
              const CircularProgressIndicator() // Show loading indicator
            else if (_usbDeviceDetailsList.isNotEmpty)
              Column(
                children: [
                  Image.asset(
                    currentLogoAsset, // Display the current logo asset
                    width: 100,
                    height: 100,
                  ),
                  ..._usbDeviceDetailsList.map((deviceDetails) {
                    String deviceId = deviceDetails['Device ID'] ?? '';
                    return Column(
                      children: [
                        Text(
                          'Device Name: ${deviceDetails['DeviceName']}',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                            fontWeight: FontWeight.bold, // Highlight text
                          ),
                        ),
                        Text(
                          'Product ID (PID): ${deviceDetails['ProductId']}',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                          ),
                        ),
                        Text(
                          'Vendor ID (VID): ${deviceDetails['VendorId']}',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                          ),
                        ),
                        devicePackageInfo(deviceDetails),
                        // Additional Info
                        Text(
                          'Manufacturer: ${deviceDetails['Manufacturer'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                          ),
                        ),
                        Text(
                          'Product Name: ${deviceDetails['ProductName'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                          ),
                        ),
                        Text(
                          'Serial Number: ${deviceDetails['SerialNumber'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                          ),
                        ),
                        Text(
                          'Firmware Version: ${deviceDetails['USB Version'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                          ),
                        ),
                        Text(
                          'Device ID: $deviceId',
                          style: const TextStyle(
                            fontSize: 16, // Change font size
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              )
            else
              const Text(
                'No USB device detected or permission denied',
                style: TextStyle(
                  fontSize: 16, // Change font size
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                // Implement the action for the "Get Ready for Use" button

                if (loading) {
                  // const CircularProgressIndicator(); // Show loading indicator
                  _dialogBuilder(context, 'No Package',
                      'Device have not loaded yet', 'Go Back', () {});
                } else if (_usbDeviceDetailsList.isNotEmpty) {
                  for (Map<String, String> deviceDetails
                      in _usbDeviceDetailsList) {
                    String packageStatus =
                        deviceDetails['Package Status'] ?? 'False';

                    if (bool.parse(packageStatus, caseSensitive: false)) {
                      _dialogBuilder(
                          context,
                          deviceDetails['Package Name'] ?? 'No package',
                          'The package is already present in your machine.',
                          'Open App',
                          () => openApp(deviceDetails['Package Name'], true));
                    } else {
                      _dialogBuilder(
                          context,
                          deviceDetails['Package Name'] ?? 'No package',
                          'The package is not downloaded',
                          'Download',
                          () => openApp(deviceDetails['Package Name'], false));
                    }
                  }
                }
              },
              child: const Text('Get Ready for Use'),
            ),
            ElevatedButton(
              onPressed: () async {
                captureRDDevice('com.scl.rdservice');
              },
              child: const Text('Get PID'),
            ),
            Text(pidBlock)
          ],
        ),
      ),
    );
  }
}
