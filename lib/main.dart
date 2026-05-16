import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';

void main() async {
  // Preserve the splash screen until the app is fully initialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await dotenv.load(fileName: ".env");
  
  runApp(const TextSnapOCRApp());
}

class TextSnapOCRApp extends StatelessWidget {
  const TextSnapOCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TextSnap OCR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5),
          primary: const Color(0xFF00BFA5),
          background: const Color(0xFFF0FFFE),
        ),
        // Apply Noto Nastaliq globally
        textTheme: GoogleFonts.notoNastaliqUrduTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.blueGrey[900],
          displayColor: Colors.blueGrey[900],
        ),
      ),
      home: const HomeScreen(),
    );
  }
}