import 'package:flutter/material.dart';
import 'package:free_dictionary_api_v2/free_dictionary_api_v2.dart';
import 'package:vocab_app/file_handling.dart';

Set getWordType(Map word) {
  Set types = {};
  for (var definition in word['definitions']) {
    if (definition['partOfSpeech'] != null) {
      types.add(definition['partOfSpeech']);
    }
  }
  return types;
}
String capitalise(String s) =>
  s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  
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
    debugPrint(error.toString() + stackTrace.toString());
    return {};
  }
}

void deleteWord(word) {
  readData().then((data) async{
    data.remove(word);
    await writeData(data, append: false);
  });
  debugPrint('deleted $word');
}

Map organiseToSpeechPart(List wordDetails) {
  Map organised = {};
  for (var definition in wordDetails) {
    if (organised[definition['partOfSpeech']] == null) {
      organised[definition['partOfSpeech']] = [];
    }
    organised[definition['partOfSpeech']].add(definition);
  }
  return organised;
}

gatherSynonyms(Map word) {
  Set synonyms = {};
  for (var definition in word['definitions']) {
    if (definition['synonyms'] != null) {
      for (var synonym in definition['synonyms']) {
        synonyms.add(synonym);
      }
    }
  }
  return synonyms.toList();
}
gatherAntonyms(Map word) {
  Set antonyms = {};
  for (var definition in word['definitions']) {
    if (definition['antonyms'] != null) {
      for (var antonym in definition['antonyms']) {
        antonyms.add(antonym);
      }
    }
  }
  return antonyms.toList();
}