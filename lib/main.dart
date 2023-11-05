import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // 引入 dart:convert 包
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

final logger = Logger(
  printer: PrettyPrinter(),
);

FirebaseFirestore db = FirebaseFirestore.instance;

final GoogleSignIn googleSignIn = GoogleSignIn();
final FirebaseAuth auth = FirebaseAuth.instance;

void main() async {
// ...
  runApp(const MyApp());
  // WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase to work

  await Firebase.initializeApp();

  // Add a new document with a generated ID
//   // db.collection("users").add(user).then((DocumentReference doc) =>
//   //     logger.i('DocumentSnapshot added with ID: ${doc.id}'));
}

Future<User?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult =
          await auth.signInWithCredential(credential);
      return authResult.user;
    }
    return null;
  } catch (e) {
    logger.e("Error signing in with Google: $e");
    return null;
  }
}

Future<void> readDataFromFirestore() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await db.collection("users").get();
  for (QueryDocumentSnapshot doc in querySnapshot.docs) {
    logger.i("User ID: ${doc.id}");
    logger.i("User Data: ${doc.data()}");
  }
}

String parseJson(String responseBody, String propertyName) {
  // 使用 json.decode 方法解析 JSON 字符串
  Map<String, dynamic> parsedJson = json.decode(responseBody);

  // 假设 JSON 包含键名为 'propertyName' 的属性
  if (parsedJson.containsKey(propertyName)) {
    // 通过键名 'propertyName' 获取属性值
    dynamic propertyValue = parsedJson[propertyName];

    // 打印属性值
    return propertyValue;

    // print('Property Value: $');
  } else {
    return 'propertyName not found in the JSON response';
    // print('propertyName not found in the JSON response');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'garbase_classifiled',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Garbage Classifier Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // int _counter = 0;
  String _scanResult = '';
  String _devDisplay = "DevDisplay";

  // parse the info from the scan result to the info of the item using api
  Future<void> getProductInfo(String barcode) async {
    final url = Uri.parse('https://barcode.monster/api/$_scanResult');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Parse and handle the API response here
      setState(() {
        _scanResult = parseJson(response.body, 'description');

        final item = {
          "Description": _scanResult,
          "barcode": barcode,
        };

        if (!_scanResult.contains("propertyName not found")) {
          db.collection("Trash").add(item);
        }
      });
    } else {
      // Handle errors, e.g., if the API call fails
      setState(() {
        _scanResult = 'Failed to get product info. Fuck you';
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      // print the result to the dev console
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the style for the buttons
    ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      onPrimary: Colors.white, // Text color (white)
      backgroundColor:
          Colors.blue.withOpacity(0.7), // Transparent blue background
      minimumSize: const Size(200, 160), // Minimum size of the button
      shape: RoundedRectangleBorder(
        // Rounded corners
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 0, // Removes elevation (shadow)
    );

    // Define the style for the button text
    TextStyle buttonTextStyle = const TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: Colors.white, // Text color (white)
    );

    // Define the style for the scan result text
    TextStyle scanResultTextStyle = const TextStyle(
      fontSize: 15,
      color: Colors.black87,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the entire body
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Scanner Button
            ElevatedButton(
              onPressed: () async {
                var barcodeResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleBarcodeScannerPage(),
                  ),
                );
                if (barcodeResult is String) {
                  setState(() {
                    _scanResult = barcodeResult;
                    getProductInfo(_scanResult);
                  });
                }
              },
              style: buttonStyle, // Use the button style defined above
              child: Text('Open Scanner', style: buttonTextStyle),
            ),
            const SizedBox(height: 20), // Spacing between the buttons
            // Scan Result Text
            Text(
              'The following is the result of the scan:',
              style: scanResultTextStyle,
            ),
            const SizedBox(height: 10), // Spacing between text and result
            // Scan Result Output
            Text(
              _scanResult,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
                height:
                    20), // Spacing between the scan result and the next button
            // Ranking Page Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RankingPage()),
                );
              },

              style: buttonStyle, // Use the button style defined above
              child: Text('Go to Ranking Page', style: buttonTextStyle),
            ),

            ElevatedButton(
              // button for sign in with google
              onPressed: () async {
                User? user = await signInWithGoogle();
                if (user != null) {
                  // User is successfully authenticated.
                } else {
                  // Sign-in with Google failed.
                }
              },
              child: const Text("Sign in with Google"),
            )
          ],
        ),
      ),
    );
  }
}

class RankingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking Page'),
      ),
      body: const Center(
        child: Text('Content is here'),
      ),
    );
  }
}
