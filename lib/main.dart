import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

// Declare rtdb as a global variable so it can be used across widgets
late FirebaseDatabase rtdb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final firebaseApp = Firebase.app();

  rtdb = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL:
        'https://maroun-task-default-rtdb.europe-west1.firebasedatabase.app',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Application',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 21, 0, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home Page'),
      routes: {
        '/waiting': (content) => const WaitingRoom(),
        '/final': (context) => const MyFinalPage(title: 'Final Page'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _goToWaitingRoom() {
    Navigator.pushNamed(context, '/waiting');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _goToWaitingRoom,
              child: const Text('Go to Waiting Room'),
            ),
          ],
        ),
      ),
    );
  }
}

class WaitingRoom extends StatefulWidget {
  const WaitingRoom({super.key});

  @override
  State<WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends State<WaitingRoom> {
  // Access the global rtdb reference
  final DatabaseReference _waitingRoomRef = rtdb.ref('waitingRoom');
  late DatabaseReference _currentUserRef;

  @override
  void initState() {
    super.initState();
    _addUserToWaitingRoom();
  }

  void _addUserToWaitingRoom() {
    // Add the user to the waiting room with a unique key
    _currentUserRef = _waitingRoomRef.push();
    _currentUserRef.set({'status': 'waiting'}).then((_) {
      // Listen for changes in the waiting room
      _waitingRoomRef.onValue.listen((event) {
        final users = event.snapshot.children.length;
        if (users >= 2) {
          // Redirect to final page if there are 2 or more users
          _redirectToFinalPage();
        }
      });
    });
  }

  void _redirectToFinalPage() {
    // Remove only the current user from the waiting room
    _currentUserRef.remove().then((_) {
      Navigator.pushReplacementNamed(context, '/final');
    });
  }

  @override
  void dispose() {
    // Remove the listener and the current user when the widget is disposed
    _currentUserRef.remove();
    _waitingRoomRef.onDisconnect().cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
      ),
      body: const Center(
        child: Text('Waiting for another user...'),
      ),
    );
  }
}

class MyFinalPage extends StatefulWidget {
  const MyFinalPage({super.key, required this.title});

  final String title;

  @override
  State<MyFinalPage> createState() => _MyFinalPageState();
}

class _MyFinalPageState extends State<MyFinalPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Center(
        child: Text('Congrats!'),
      ),
    );
  }
}
