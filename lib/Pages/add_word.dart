import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 75),
                child: TextField(
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                  ), 
                  onSubmitted: (value) {
                    addWordToList(value, context);
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
void addWordToList(String word, context) {
  LoadingOverlay loadingOverlay = LoadingOverlay();
  readData().then((data) async{
    loadingOverlay.showLoadingOverlay(context);
    Map wordDetails = await getWordDef(word);
    data[word] = wordDetails;
    loadingOverlay.removeLoadingOverlay();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF151515),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Word: ${capitalise(word)}'),
            const SizedBox(height: 10),
            Text('Definitions: ${wordDetails['definitions'][0]['definition']}'),
            const SizedBox(height: 10),
            Text('Word Type: ${getWordType(wordDetails).join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Navigator.pop(context);

    // writeData(data, append: false);
  });
}