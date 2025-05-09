import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';

class WordList extends StatelessWidget {
  const WordList({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
    future: readData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        } else if (snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final word = snapshot.data!.keys.elementAt(index);
                return ListTile(
                  title: Text(word),
                  subtitle: Text(snapshot.data![word]['definitions'][0]['definition']),
                );
              },
            ),
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }
}

