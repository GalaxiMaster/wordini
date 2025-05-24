import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:free_dictionary_api_v2/free_dictionary_api_v2.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/widgets.dart';
import 'dart:convert';

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
      'dateAdded': DateTime.now().toString(),
      'definitions': []// [{
      //   'definition': '',
      //   'example': '',
      //   'partOfSpeech': '',
      //   'synonyms': [],
      //   'antonyms': [],
      // }],
    };
    String? apiKey = dotenv.env['MERRIAM_WEB_API_KEY'];
    if (apiKey == null) {
      throw Exception('MERRIAM_WEB_API_KEY not found in .env file'); // TODO handle.
    }
    final String url = 'https://www.dictionaryapi.com/api/v3/references/collegiate/json/$word?key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Map mainData = data[0];
      if (data.isNotEmpty && mainData is Map<String, dynamic>) { // TODO Exapnd past the first result
        debugPrint('Word: $word');
        wordDetails['definitions'] = mainData['shortdef'] ?? []; // TODO understand bigger definition structure
        wordDetails['synonyms'] = [];
        wordDetails['firstUsed'] = mainData['date']?.split('{')?[0] ?? ''; // Maybe solidify this further
        wordDetails['etymology'] = mainData['et']?[0]?[1] ?? '';
        wordDetails['partOfSpeech'] = mainData['fl'] ?? '';
        wordDetails['stems'] = mainData['meta']?['stems'] ?? [];
        debugPrint('jiejlge');
      } else {
        debugPrint('No definitions found for "$word".');
      }
    } else {
      debugPrint('Failed to load definition: ${response.statusCode}');
    }



    debugPrint(response.toString());
    // response[0].meanings?.forEach((meaning) {
    //   meaning.definitions?.forEach((definition) {
    //     Map meaningDetails = {
    //       'partOfSpeech': meaning.partOfSpeech,
    //       'definition': definition.definition,
    //       'example': definition.example,
    //       'synonyms': definition.synonyms,
    //       'antonyms': definition.antonyms,
    //     };

    //     wordDetails['definitions'].add(meaningDetails);
    //   });
    // });
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
Future<bool?> checkDefinition(word, userDef, actualDef, context) async{
  // the system message that will be sent to the request.
  final systemMessage = OpenAIChatCompletionChoiceMessageModel(
    content: [
      OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "Answer if the user given definition matches the word with only yes or no as an answer",
      ),
    ],
    role: OpenAIChatMessageRole.assistant,
  );

    // the user message that will be sent to the request.
  final userMessage = OpenAIChatCompletionChoiceMessageModel(

    content: [
      OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "Does the user's definition '$userDef' correctly define the word '$word'", // , whose definition is '$actualDef'? // ! TODO this doesnt account for multiple definitions so its out currently
      ),
    ],
    role: OpenAIChatMessageRole.user,
  );

  // all messages to be sent.
  final requestMessages = [
    systemMessage,
    userMessage,
  ];

  try {
    OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-4",
      seed: 6,
      messages: requestMessages,
      temperature: 0.2,
      maxTokens: 500,
    );
    String answer = chatCompletion.choices.first.message.content!.first.text.toString();
    debugPrint(answer);
    debugPrint(chatCompletion.systemFingerprint.toString());
    debugPrint(chatCompletion.usage.promptTokens.toString());
    debugPrint(chatCompletion.id);
    return answer.toLowerCase() == 'yes' ? true : false;

  } catch (e) {
    if (e is HandshakeException ||
        e is SocketException ||
        e is HttpException) {
      errorOverlay(context, 'Failed to connect to server, please check your internet connection');
    }
    debugPrint(e.toString());
    // TODO handle more error types
  }
  return null;
}