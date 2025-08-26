import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Pages/word_details.dart';
import 'package:wordini/Providers/goal_providers.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/file_handling.dart';
import 'package:wordini/widgets.dart';
import 'package:wordini/word_functions.dart';

class AddWord extends ConsumerStatefulWidget {
  const AddWord({super.key});
  @override
  AddWordState createState() => AddWordState();
}

class AddWordState extends ConsumerState<AddWord> {
  final FocusNode _addWordTextBoxFN = FocusNode();
  final TextEditingController _addWordTextBoxController = TextEditingController();
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
    _addWordTextBoxController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Word'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
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
                child: Column(
                  children: [
                    TextField(
                      controller: _addWordTextBoxController,
                      focusNode: _addWordTextBoxFN,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                      ), 
                      onSubmitted: (value) async{
                        addWordToList(value.toLowerCase(), context).then((result) {
                          if (result) {
                            ref.invalidate(wordDataFutureProvider);
                          }
                        });
                      },
                      onChanged: (value) => setState(() {}), // TODO optomise
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async{
                        if (_addWordTextBoxController.text.isNotEmpty){
                          final allTags = await gatherTags();
                          if (!context.mounted) return;
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => WordDetails(
                              word: {
                                "word": _addWordTextBoxController.text,
                                "dateAdded": DateTime.now().toString(),
                                "entries": {
                                  // "": {
                                  //   "synonyms": {},
                                  //   "etymology": "",
                                  //   "partOfSpeech": "",
                                  //   "quotes": [],
                                  //   "details": [
                                  //     {
                                  //       // "definitions": [
                                  //       //   // [
                                  //       //   //   {
                                  //       //   //     "definition": "",
                                  //       //   //     "example": []
                                  //       //   //   }
                                  //       //   // ],
                                  //       // ],
                                  //       // "shortDefs": [],
                                  //       // "firstUsed": "",
                                  //       // "stems": [],
                                  //       // "homograph": 1
                                  //     },
                                  //   ],
                                  //   "selected": true
                                  // },
                                }
                              }, 
                              editModeState: true,
                              allTags: allTags,
                              addWordMode: true,
                            ))
                          );
                          if (result ?? false) {
                            ref.read(wordsThisWeekDataProvider.notifier).incriment();
                            ref.invalidate(wordDataFutureProvider); // TODO optomise by adding to the existing wordData provider instead of refreshing
                          }
                        }
                      },
                      child: Text(
                        'Word not found? Add manually',
                        style: TextStyle(
                          color: _addWordTextBoxController.text.isNotEmpty ? Colors.blue : Colors.grey,
                          // decoration: TextDecoration.underline,
                          // decorationColor: Colors.blue,
                          // decorationStyle: TextDecorationStyle.dotted
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
Future<bool> addWordToList(String word, context) async{
  LoadingOverlay loadingOverlay = LoadingOverlay();
  final Map data = await readData();
  if (data.containsKey(word)) {
    messageOverlay(context, 'Already added word');
    return false;
  }
  loadingOverlay.showLoadingOverlay(context);
  Map wordDetails;
  
  try {
    wordDetails = await getWordDetails(word);
  } on FormatException {
    loadingOverlay.removeLoadingOverlay();
    messageOverlay(context, 'Invalid word');
    return false;
  } catch (e) {
    loadingOverlay.removeLoadingOverlay();
    messageOverlay(context, 'Error fetching word details: $e');
    return false;
  }
  if (wordDetails['entries'].isEmpty) {
    loadingOverlay.removeLoadingOverlay();
    messageOverlay(context, 'Word not found');
    return false;
  }

  loadingOverlay.removeLoadingOverlay();
  final Set allTags = await gatherTags();
  bool? result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => WordDetails(word: wordDetails, addWordMode: true, allTags: allTags,))
  );
  return result ?? false;
}