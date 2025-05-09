import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';

class AddWord extends StatefulWidget {
  AddWord({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _AddWordState createState() => _AddWordState();
}

class _AddWordState extends State<AddWord> {
@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Add Words',
                style: TextStyle(
                  fontSize: 24, 
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Word',
                  ),
                  onFieldSubmitted: (value) {
                    addWordToList(value);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
void addWordToList(String value) {
  readData().then((data) {
    data[value] = {'Word: $value'};
    writeData(data, append: false);
  });
}
