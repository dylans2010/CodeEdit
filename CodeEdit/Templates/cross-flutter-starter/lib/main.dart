import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{PROJECT_NAME}}',
      home: Scaffold(
        appBar: AppBar(title: const Text('{{PROJECT_NAME}}')),
        body: const Center(child: Text('Hello from Flutter!')),
      ),
    );
  }
}
