import 'package:flutter/material.dart';
import 'package:free_dictionary_api_v2/free_dictionary_api_v2.dart';
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
void addWordToList(String word) {
  readData().then((data) async{
    Map wordDetails = await getWordDef(word);
    data[word] = wordDetails;
    writeData(data, append: false);
  });
}

Future<Map> getWordDef(String word) async {
  try {
    Map wordDetails = {
      'word': word,
      'definitions': []// [{
      //   'definition': '',
      //   'example': '',
      //   'partOfSpeech': '',
      //   'synonyms': [],
      //   'antonyms': [],
      // }],
    };
    // TODO probably switch to a different API, this ones not it
    final dictionary = FreeDictionaryApiV2();
    final response = await dictionary.getDefinition(word);
    debugPrint(response.toString());
    response[0].meanings?.forEach((meaning) {
      meaning.definitions?.forEach((definition) {
        Map meaningDetails = {
          'partOfSpeech': meaning.partOfSpeech,
          'definition': definition.definition,
          'example': definition.example,
          'synonyms': definition.synonyms,
          'antonyms': definition.antonyms,
        };

        wordDetails['definitions'].add(meaningDetails);
      });
    });
    return wordDetails;
  } on FreeDictionaryException catch (error, stackTrace) {
    debugPrint(error.toString());
    return {};
  }

}