import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/app_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const VisionGuideApp());
}

class VisionGuideApp extends StatelessWidget {
  const VisionGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'VisionGuide AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.yellow.shade400,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Roboto',
        ),
        home: const AppScreen(),
      ),
    );
  }
}
