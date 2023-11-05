// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Ranking Page',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: RankingPage(),
//     );
//   }
// }

// class RankingPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: <Widget>[
//           // Top half with an image and text "Ranking"
//           Expanded(
//             flex: 1, // This takes half of the screen space
//             child: Stack(
//               fit: StackFit.expand,
//               children: <Widget>[
//                 Image.network(
//                   'https://c4.wallpaperflare.com/wallpaper/621/106/436/
//                   nature-scenery-wallpaper-preview.jpg', // Replace with your image asset
//                   fit: BoxFit.cover,
//                 ),
//                 Container(
//                   color: Colors.black.withOpacity(0.3), // Dark overlay
//                 ),
//                 Center(
//                   child: Text(
//                     'Ranking',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 40,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Bottom half with a fancy color and a centered button
//           Expanded(
//             flex: 1, // This takes the remaining half
//             child: Container(
//               color: Colors.teal, // Fancy color for the bottom half
//               child: Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // TODO: Insert what happens when you press the button
//                   },
//                   child: Text('Ranking'),
//                   style: ElevatedButton.styleFrom(
//                     primary: Colors.white, // Button color
//                     onPrimary: Colors.teal, // Text color
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
