

import 'package:flutter/material.dart';

class AutoPaths extends StatefulWidget {
  const AutoPaths({super.key});

  @override
  State<AutoPaths> createState() => _AutoPathsState();
}

class _AutoPathsState extends State<AutoPaths> {
  final List<String> autoPathImages = ['assets/image1.jpg', 'assets/image2.jpg', 'assets/image3.jpg'];
  String? _selectedPath;

  void _setPath(int index) {
    setState(() {
      _selectedPath = autoPathImages[index];
    });
  }


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Column(
            children: [
              const Text("Auto Paths", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                  itemCount: 10, // Replace with the actual number of paths
                  itemBuilder: (context, index) {
                  return Card(
                    child: InkWell(
                      onTap: () => _setPath(index),
                      child: ListTile(
                      title: Text('Path ${index + 1}'),
                      subtitle: Text('Details for Path ${index + 1}'),
                      ),
                    ),
                  );
                  },
                ),
              ),
            ]
          )
        ),
        Container(    // Vertical divider
          width: 2,
          color: Colors.black,
        ),
        Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset(_selectedPath ?? 'assets/errorimg.jpg'),
            ),
        ),
      ]
    );
  }
}