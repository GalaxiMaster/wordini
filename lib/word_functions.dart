import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/widgets.dart';
import 'dart:convert';

Set getWordType(Map word) {
  Set types = {};
  for (var definition in word['entries']) {// TODO multple 
    if (definition['partOfSpeech'] != null) {
      types.add(definition['partOfSpeech']);
    }
  }
  return types;
}

String capitalise(String s) {
  if (s.isEmpty) return s;
  final cleanedText = s.replaceFirst(RegExp(r'^\{[^}]*\}'), '');
  final letterIndex = s.indexOf(RegExp(r'[A-Za-z]'), s.indexOf(cleanedText));

  if (letterIndex == -1) return s; // No letter found
  final result = s.substring(0, letterIndex) +
      s[letterIndex].toUpperCase() +
      s.substring(letterIndex + 1);
  return result;
}

Future<Map> getWordDetails(String word) async {
  try {
    Map wordDetails = {
      'word': word,
      'dateAdded': DateTime.now().toString(),
      'entries': []
    };
    String? apiKey = dotenv.env['MERRIAM_WEB_API_KEY'];
    if (apiKey == null) {
      throw Exception('MERRIAM_WEB_API_KEY not found in .env file'); // TODO handle.
    }
    final String url = 'https://www.dictionaryapi.com/api/v3/references/collegiate/json/$word?key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty && data[0] is Map<String, dynamic>) { // TODO Exapnd past the first result
        for (Map mainData in data){
          Map wordDeets = {
            // 'definitions': [],
            // 'quotes': [],
            // 'partOfSpeech': '',
            // 'synonyms': [],
            // 'etymology': '',
            // 'stems': '',
            // 'firstUsed': '', 
          };
          try{
            wordDeets['shortDefs'] = mainData['shortdef'] ?? [];
            wordDeets['synonyms'] = parseSynonyms(mainData);
            wordDeets['firstUsed'] = mainData['date']?.replaceAll(RegExp(r'\{[^}]*\}'), '') ?? '';
            wordDeets['etymology'] = mainData['et']?[0]?[1] ?? '';
            wordDeets['partOfSpeech'] = mainData['fl'] ?? '';
            wordDeets['stems'] = mainData['meta']?['stems'] ?? [];
            wordDeets['quotes'] = mainData['quotes'] ?? [];
            wordDeets['definitions'] = parseDefinitions(mainData['def'][0]);

            wordDetails['entries'].add(wordDeets);
          } catch(e){
            throw FormatException('Error parsing word details: $e');
          }
        }
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
  } catch (e) {
    if (e is FormatException) rethrow;
    debugPrint('Error fetching word details: $e');
    return {
      'word': word,
      'dateAdded': DateTime.now().toString(),
      'entries': [],
    };
  }
}

Map<String, Map<String, dynamic>> parseSynonyms(Map entry) {
  final Map<String, Map<String, dynamic>> result = {};

  if (!entry.containsKey('syns')) return result;

  for (final synGroup in entry['syns']) {
    final pt = List.from(synGroup['pt']);
    String? currentTerm;
    String? currentDefinition;
    List<String> currentExamples = [];

    for (int i = 0; i < pt.length; i += 2) {
      final textItem = pt[i];
      final visItem = (i + 1 < pt.length) ? pt[i + 1] : null;

      if (textItem[0] == 'text') {
        final text = textItem[1] as String;

        // Extract first {sc}...{/sc} term
        final regex = RegExp(r'{sc}(.*?){/sc}');
        final match = regex.firstMatch(text);
        if (match != null) {
          currentTerm = match.group(1);
        }

        currentDefinition = text;
      }

      currentExamples = [];
      if (visItem != null && visItem[0] == 'vis') {
        for (final vis in visItem[1]) {
          currentExamples.add(vis['t']);
        }
      }

      if (currentTerm != null && currentDefinition != null) {
        result[currentTerm] = {
          'definition': capitalise(currentDefinition.trim()),
          'example': currentExamples,
        };
      }

      // Clear term for next group unless new one is found
      currentTerm = null;
      currentDefinition = null;
    }
  }

  return result;
}

List parseDefinitions(Map data){
  final List<List<dynamic>> sseq = List.from(data['sseq']);

  final definitions = <List<Map<String, dynamic>>>[];

  for (var i = 0; i < sseq.length; i++) {
    final group = sseq[i];
    final groupList = <Map<String, dynamic>>[];

    for (var j = 0; j < group.length; j++) {
      final item = group[j];
      if (item[0] == 'sense') {
        final sense = item[1];
        final dt = List.from(sense['dt']);
        String defText = '';
        List<String> examples = [];

        for (var entry in dt) {
          if (entry[0] == 'text') {
            defText += entry[1].trim() + ' ';
          } else if (entry[0] == 'vis') {
            for (var vis in entry[1]) {
              examples.add(vis['t']);
            }
          }
        }
        if (cleanText(defText).isEmpty) {
          debugPrint('Empty definition found in group $i, item $j | $defText');
          continue; // Skip empty definitions
        }
        groupList.add({
          'definition': capitalise(defText.trim()),
          'example': examples,
        });
      }
    }
    if (groupList.isEmpty) {
      debugPrint('Empty group found at index $i');
      continue; // Skip empty groups
    }
    definitions.add(groupList);
  }
    for (var i = 0; i < definitions.length; i++) {
    for (var j = 0; j < definitions[i].length; j++) {
      debugPrint('definition[$i][$j]["definition"] = ${definitions[i][j]["definition"]}');
      debugPrint('definition[$i][$j]["example"] = ${definitions[i][j]["example"]}\n');
    }
  }
  return definitions;
}

String cleanText(String input) {
  final tagRegex = RegExp(r'\{[^}]*\}');
  final punctuationRegex = RegExp(r'[\p{P}]', unicode: true);

  String noTags = input.replaceAll(tagRegex, '');
  String cleaned = noTags.replaceAll(punctuationRegex, '');
  return cleaned.trim(); // <-- trim whitespace
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
  for (var entry in organised.entries) {
    debugPrint('Speech Part: ${entry.key}  -----------------------------------------------------------------');
    for (var definition in entry.value){
      for (var def in definition['definitions']) {
        debugPrint('**** newform ****');
        for (var definit in def){
          debugPrint('definition: ${definit['definition']}');
        }
      }
    }
  }
  
  return organised;
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

String indexToLetter(int index) {
  return String.fromCharCode('a'.codeUnitAt(0) + index);
}