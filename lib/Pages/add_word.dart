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
  final FocusNode _addWordTextBoxFN = FocusNode();
  @override
  initState() {
    super.initState();
    // Focus on the text box when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWordTextBoxFN.requestFocus();
    });
  }
    @override
  void dispose() {
    _addWordTextBoxFN.dispose();
    super.dispose();
  }
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
                  focusNode: _addWordTextBoxFN,
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
    Map wordDetails;
    
    try {
      wordDetails = await getWordDetails(word);
    } on FormatException {
      loadingOverlay.removeLoadingOverlay();
      errorOverlay(context, 'Invalid word');
      return;
    } catch (e) {
      loadingOverlay.removeLoadingOverlay();
      errorOverlay(context, 'Error fetching word details: $e');
      return;
    }
    if (wordDetails['entries'].isEmpty) {
      loadingOverlay.removeLoadingOverlay();
      errorOverlay(context, 'Word not found');
      return;
    }

    loadingOverlay.removeLoadingOverlay();
    final Set allTags = await gatherTags();
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WordDetails(word: wordDetails, addWordMode: true, allTags: allTags,))
    );
    if (!(result ?? false)) {
      return;
    }
    Navigator.pop(context);

    writeWord(word, wordDetails);
  });
}