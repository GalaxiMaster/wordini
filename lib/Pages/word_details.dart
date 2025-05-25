import 'package:flutter/material.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

class WordDetails extends StatefulWidget {
  final Map word;
  const WordDetails({super.key, required this.word});
  @override
  // ignore: library_private_types_in_public_api
  _WordDetailstate createState() => _WordDetailstate();
}

class _WordDetailstate extends State<WordDetails> {
  @override
  Widget build(BuildContext context) {
    // List synonyms = gatherSynonyms(widget.word);
    // List antonyms = gatherAntonyms(widget.word);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capitalise(widget.word['word']),
                style: TextStyle(fontSize: 24),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 100),
                child: Divider(),
              ),
              const SizedBox(height: 20),
              for (var speechType in organiseToSpeechPart(widget.word['entries']).entries) ...[
                Text(
                  capitalise(speechType.key),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                for (var entry in speechType.value.asMap().entries)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var definition in entry.value['definitions'])
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: MWTaggedText(
                            '${entry.key + 1}. ${definition[0]['definition']}',
                          ),
                        ),
                      // if (entry.value['example'] != null) 
                      //   Padding(
                      //     padding: const EdgeInsets.only(left: 5),
                      //     child: Text(
                      //       'Example: ${entry.value['example']}',
                      //       style: const TextStyle(fontStyle: FontStyle.italic),
                      //     ),
                      //   )
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

