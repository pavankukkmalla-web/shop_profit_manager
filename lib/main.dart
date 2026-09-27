import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ShopProfitManager());
}

class ShopProfitManager extends StatelessWidget {
  const ShopProfitManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop Profit Manager',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      home: const HomeScreen(),
    );
  }
}