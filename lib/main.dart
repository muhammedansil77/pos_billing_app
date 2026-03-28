// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';

// late List<CameraDescription> cameras;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(home: CameraScreen());
//   }
// }

// class CameraScreen extends StatefulWidget {
//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   late CameraController controller;

//   @override
//   void initState() {
//     super.initState();
//     if (cameras.isEmpty) {
//       print("No cameras available");
//       return;
//     }
//     controller = CameraController(cameras[0], ResolutionPreset.medium);

//     controller.initialize().then((_) {
//       if (!mounted) return;
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     if (controller.value.isInitialized) {
//        controller.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (cameras.isEmpty) {
//       return Scaffold(body: Center(child: Text("No cameras found.")));
//     }
//     if (!controller.value.isInitialized) {
//       return Center(child: CircularProgressIndicator());
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text("Camera")),
//       body: CameraPreview(controller),
//       floatingActionButton: FloatingActionButton(
//         child: Icon(Icons.camera),
//         onPressed: () async {
//           await controller.takePicture();
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/billing/pos_screen.dart';
import 'screens/customers/credit_customers_screen.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/add_edit_product_screen.dart';
import 'screens/billing/sales_history_screen.dart';
import 'providers/localization_provider.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/customer_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: const POSBillingApp(),
    ),
  );
}

class AppState with ChangeNotifier {}

class POSBillingApp extends StatelessWidget {
  const POSBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Billing App',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainNavigationScreen(),
        '/pos': (context) => const POSScreen(),
        '/products': (context) => const ProductListScreen(),
        '/customers': (context) => const CustomerListScreen(),
        '/credit': (context) => const CreditCustomersScreen(),
        '/add-product': (context) => const AddEditProductScreen(),
        '/sales': (context) => const SalesHistoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
