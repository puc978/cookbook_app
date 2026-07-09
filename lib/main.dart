import 'package:flutter/material.dart';
import 'screens/main_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RecipeListScreen(),
    );
  }
}
