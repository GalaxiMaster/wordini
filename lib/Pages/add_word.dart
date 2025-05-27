import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/word_details.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

class AddWord extends StatefulWidget {
  const AddWord({super.key});
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
    if (data.containsKey(word)) {
      errorOverlay(context, 'Already added word');
      return;
    }
    loadingOverlay.showLoadingOverlay(context);
    Map wordDetails = await getWordDetails(word);
    if (wordDetails['entries'].isEmpty) {
      loadingOverlay.removeLoadingOverlay();
      errorOverlay(context, 'Word not found');
      return;
    }
    data[word] = wordDetails;
    loadingOverlay.removeLoadingOverlay();
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WordDetails(word: wordDetails, addWordMode: true,)),
    );
    if (!(result ?? false)) {
      return;
    }
    Navigator.pop(context);

    writeData(data, append: false);
  });
}