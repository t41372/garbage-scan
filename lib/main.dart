import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // 引入 dart:convert 包
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

const barcode_api_key =
    "a29a40131b728b5af7c18276e8c11934d06daac25bce6475c4d12c83850d55dd";

final logger = Logger(
  printer: PrettyPrinter(),
);

FirebaseFirestore db = FirebaseFirestore.instance;

void main() async {
// ...
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());

  // WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase to work

  // Add a new document with a generated ID
//   // db.collection("users").add(user).then((DocumentReference doc) =>
//   //     logger.i('DocumentSnapshot added with ID: ${doc.id}'));
}

Future<User?> signInWithGoogle() async {
  GoogleSignIn googleSignIn = GoogleSignIn();
  FirebaseAuth auth = FirebaseAuth.instance;

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
    await Firebase.initializeApp();
    return null;
  } catch (e) {
    logger.e("Error signing in with Google: $e");
    await Firebase.initializeApp();
    return null;
  }
}

Future<void> increaseUserScore(String userId) async {
  try {
    QuerySnapshot userQuerySnap =
        await db.collection("users").where("userId", isEqualTo: userId).get();
    logger.i("User found? ${userQuerySnap.toString()}, userid: $userId");

    if (userQuerySnap.docs.isNotEmpty) {
      // 获取第一个匹配的文档
      DocumentSnapshot? firstDocument = userQuerySnap.docs[0];

      dynamic score = firstDocument.get('score');
      int newScore = score + 1;
      await firstDocument.reference.update({'score': newScore});
    }
  } catch (e) {
    logger.e("Error incrementing score: $e");
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

String parseJson(String responseBody, String propertyName, String name2) {
  // 使用 json.decode 方法解析 JSON 字符串
  Map<String, dynamic> parsedJson = json.decode(responseBody);

  // 假设 JSON 包含键名为 'propertyName' 的属性
  if (parsedJson.containsKey(propertyName)) {
    // 通过键名 'propertyName' 获取属性值
    dynamic propertyValue = parsedJson[propertyName][name2];

    // 打印属性值
    return propertyValue;

    // print('Property Value: $');
  } else {
    return 'propertyName not found in the JSON response';
    // print('propertyName not found in the JSON response');
  }
}

Future<String> useAI(String _scanResult) async {
  // add the prompt to the AI prompt collection
  final aiPrompt = {
    "prompt":
        "How to recycle {{item_to_recycle}} properly? Please only include actionable steps.",
    "item_to_recycle": _scanResult,
    "response": ""
  };
  db.collection("generate").add(aiPrompt);
  QuerySnapshot userQuerySnap = await db
      .collection("generate")
      .where("item_to_recycle", isEqualTo: _scanResult)
      .get();
  logger.i("Finished QS now");

  while (userQuerySnap.docs.isNotEmpty) {
    DocumentSnapshot? firstDocument = userQuerySnap.docs[0];
    logger.i("First document: ${firstDocument.get('status')}");
    logger.i("First document: ${firstDocument.get('status')['state']}");
    if (await firstDocument.get('status')['state'] == "COMPLETED") {
      dynamic response = await firstDocument.get("output");
      logger.i("AI response: $response");
      return response;
    } else {
      // sleep
      await Future.delayed(Duration(seconds: 1));
    }
  }
  logger.i("AI response not found");
  return "AI response not found";
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
  String _currentUserId = "";
  String _currentName = "Sign in with Google...";
  String _aiResponse = "";

  // parse the info from the scan result to the info of the item using api
  Future<void> getProductInfo(String barcode) async {
    final url = Uri.parse(
        'https://go-upc.com/api/v1/code/$barcode?key=$barcode_api_key');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Parse and handle the API response here
      _scanResult = parseJson(response.body, 'product', 'name');
      logger.i("Product name: $_scanResult");
      final item = {
        "Description": _scanResult,
        "barcode": barcode,
      };

      if (!_scanResult.contains("propertyName not found")) {
        db.collection("Trash").add(item);
        _aiResponse = await useAI(_scanResult);
        showInfoDialog(_aiResponse);
      }
      setState(() {
        increaseUserScore(_currentUserId);
      });
    } else {
      // Handle errors, e.g., if the API call fails
      setState(() {
        _scanResult = 'Failed to get product info.';
      });
    }
  }

  void showInfoDialog(String response) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Response Dialog"),
          content: Text(response),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
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
      backgroundColor: Color.fromARGB(255, 56, 86, 237)
          .withOpacity(0.7), // Transparent blue background
      minimumSize: const Size(100, 60), // Minimum size of the button
      shape: RoundedRectangleBorder(
        // Rounded corners
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 0, // Removes elevation (shadow)
    );
    ButtonStyle buttonStyle2 = ElevatedButton.styleFrom(
      onPrimary: const Color.fromARGB(255, 255, 255, 255), // Text color (white)
      backgroundColor: Color.fromARGB(255, 118, 134, 216)
          .withOpacity(0.7), // Transparent blue background
      fixedSize: const Size(150, 40), // Minimum size of the button
      shape: RoundedRectangleBorder(
        // Rounded corners
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 0, // Removes elevation (shadow)
    );

    // Define the style for the button text
    TextStyle buttonTextStyle = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.white, // Text color (white)
    );

    // Define the style for the scan result text
    TextStyle scanResultTextStyle = const TextStyle(
      fontSize: 15,
      color: Color.fromARGB(221, 255, 255, 255),
    );

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
              "https://img.freepik.com/free-photo/abstract-textured-backgound_1258-30456.jpg"), // Replace with your image URL
          fit: BoxFit.cover, // This will cover the entire background
        ),
      ),
      child: Scaffold(
        backgroundColor: Color.fromARGB(
            0, 0, 0, 0), // Scaffold background is now transparent
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0), // Padding around the entire body
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  var barcodeResult = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleBarcodeScannerPage(),
                    ),
                  );
                  if (barcodeResult is String) {
                    _scanResult = barcodeResult;
                    await getProductInfo(_scanResult);
                    // _aiResponse 5= await useAI(_scanResult);
                    // logger.i("AI response: $_aiResponse");
                    setState(() {});
                    // showInfoDialog(_aiResponse);
                  }
                },
                style: buttonStyle, // Use the button style defined above
                child: Text('Open Scanner', style: buttonTextStyle),
              ),
              const SizedBox(height: 10), // Spacing between the buttons
              // Scan Result Text
              Text(
                'The following is the result of the scan:',
                style: scanResultTextStyle,
              ),
              const SizedBox(height: 10), // Spacing between text and result
              // Scan Result Output
              Text(
                _scanResult,
                style: buttonTextStyle,
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
              const SizedBox(height: 20),
              ElevatedButton(
                // ! =============== button for sign in with google
                onPressed: () async {
                  await signInWithGoogle().then((value) async {
                    if (value != null) {
                      _currentUserId = value!.uid;
                      _currentName = value.displayName ?? "Not login";

                      QuerySnapshot querySnapshot = await db
                          .collection("users")
                          .where("userId", isEqualTo: _currentUserId)
                          .get();

                      if (querySnapshot.size > 0) {
                        // user exists
                        // do nothing
                      } else {
                        // user does not exist
                        db.collection("users").add({
                          "userId": _currentUserId,
                          "name": _currentName,
                          "score": 0,
                        });
                      }
                      setState(() {});
                    } else {
                      setState(() {
                        _currentName = "Not login";
                      });
                    }
                  });
                },

                child: Text(_currentName),
                style: buttonStyle2,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RankingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection("users").get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          List<int> scores = [];

          if (snapshot.hasData) {
            for (QueryDocumentSnapshot doc in snapshot.data!.docs) {
              int score = doc["score"] as int;
              scores.add(score);
            }
          }
          return SafeArea(
            child: Column(
              children: [
                const Text(
                  'All Scores:',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
                for (int score in scores) Text(score.toString()),
              ],
            ),
          );
        },
      ),
    );
  }
}
