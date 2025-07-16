import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:wordini/widgets.dart';
import 'dart:convert';

Set getWordType(Map word) {
  return word['entries'].keys.toSet();
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
      'entries': {} // Now a map keyed by partOfSpeech
    };
    String? apiKey = dotenv.env['MERRIAM_WEB_API_KEY'];
    if (apiKey == null) {
      throw Exception('MERRIAM_WEB_API_KEY not found in .env file');
    }
    final String url = 'https://www.dictionaryapi.com/api/v3/references/collegiate/json/$word?key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
        for (Map mainData in data) {
          // var dataWordId = mainData['meta']['id'].split(':')[0].replaceAll(RegExp(r'[\s-]+'), '').toLowerCase();
          final bool inStems = mainData['meta']['stems'].contains(word);
          debugPrint(inStems.toString());
          if (!inStems) continue;
          Map wordDeets = {};
          try {
            String partOfSpeech = mainData['fl'] ?? '';
            int i = 2;
            while (wordDetails['entries'].containsKey(partOfSpeech)){
              partOfSpeech = '$partOfSpeech:$i';
              i++;
            }
            if (partOfSpeech.isEmpty) partOfSpeech = 'unknown';
            if (wordDetails['entries'][partOfSpeech] == null) {
              wordDetails['entries'][partOfSpeech] = {
                'synonyms': {},
                'etymology': '',
                'partOfSpeech': partOfSpeech,
                'quotes': [],
                'details': []
              };
            }
            wordDeets['definitions'] = parseDefinitions(mainData['def'][0]);
            wordDeets['shortDefs'] = mainData['shortdef'] ?? [];
            wordDeets['firstUsed'] = mainData['date']?.replaceAll(RegExp(r'\{[^}]*\}'), '') ?? '';
            wordDeets['stems'] = mainData['meta']?['stems'] ?? [];
            wordDeets['homograph'] = mainData['hom'] ?? wordDetails['entries'][partOfSpeech]['details'].length + 1;

            wordDetails['entries'][partOfSpeech]['synonyms'].addAll(parseSynonyms(mainData));
            wordDetails['entries'][partOfSpeech]['etymology'] += mainData['et']?[0]?[1] ?? '';
            wordDetails['entries'][partOfSpeech]['partOfSpeech'] = mainData['fl'] ?? '';
            wordDetails['entries'][partOfSpeech]['quotes'].addAll(mainData['quotes'] ?? []);
            
            if (wordDeets['definitions'].isEmpty) {
              debugPrint('No definitions found for "$word" in part of speech "$partOfSpeech".');
              continue; // Skip if no definitions found
            }
            wordDetails['entries'][partOfSpeech]['details'].add(wordDeets);
          } catch (e) {
            continue;
            // throw FormatException('Error parsing word details: $e');
          }
        }
        // gather all stems and intersect them and then choose the smallest one
        Set<String>? allStems;

        wordDetails['entries'].forEach((key, value) {
          value['details'].forEach((detail) {
            var stems = Set<String>.from(detail['stems']);

            if (allStems == null) {
              allStems = stems;
            } else {
              allStems = allStems!.intersection(stems);
            }
          });
        });
        word = allStems!.reduce((a, b) => a.length <= b.length ? a : b); // find smallest in list
        wordDetails['word'] = word;
      } else {
        debugPrint('No definitions found for "$word".');
      }
    } else {
      debugPrint('Failed to load definition: \\${response.statusCode}');
    }

    debugPrint(response.toString());
    wordDetails['entries'] = validateWordData(wordDetails['entries']);
    return wordDetails;
  } catch (e) {
    if (e is FormatException) rethrow;
    debugPrint('Error fetching word details: $e');
    return {
      'word': word,
      'dateAdded': DateTime.now().toString(),
      'entries': {},
    };
  }
}

Map validateWordData(Map data){
  for (MapEntry speechType in data.entries){
    speechType.value['selected'] = data.keys.toList().indexOf(speechType.key) == 0 ? true : false;
    // speechType.value['synonyms'] ??= {};
    // speechType.value['etymology'] ??= '';
    // speechType.value['details'] ??= [];
  }
  return data;
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

// Improved parseDefinitions to preserve sn and flatten for easier rendering
List<Map<String, dynamic>> parseDefinitions(Map data) {
  final List<List<dynamic>> sseq = List.from(data['sseq']);

  List<Map<String, dynamic>> extractSenses(List group) {
    final List<Map<String, dynamic>> senses = [];

    for (var item in group) {
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

        if (cleanText(defText).isEmpty) continue;

        senses.add({
          'definition': capitalise(defText.trim()),
          'example': examples,
        });
      } else if (item[0] == 'pseq') {
        senses.addAll(extractSenses(item[1]));
      }
    }
    return senses;
  }

  // Flattened list of all senses with their sn
  List<Map<String, dynamic>> allSenses = [];
  for (var group in sseq) {
    allSenses.addAll(extractSenses(group));
  }
  return allSenses;
}

String cleanText(String input) {
  final tagRegex = RegExp(r'\{[^}]*\}');
  final punctuationRegex = RegExp(r'[\p{P}]', unicode: true);

  String noTags = input.replaceAll(tagRegex, '');
  String cleaned = noTags.replaceAll(punctuationRegex, '');
  return cleaned.trim(); // <-- trim whitespace
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

Future<bool?> checkDefinition(word, userDef, partOfSpeech, context) async{
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
        "Does the user's definition '$userDef' correctly define the $partOfSpeech '$word'", // , whose definition is '$actualDef'? // ! TODO this doesnt account for multiple definitions so its out currently
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
      messageOverlay(context, 'Failed to connect to server, please check your internet connection');
    }
    debugPrint(e.toString());
    // TODO handle more error types
  }
  return null;
}

String indexToLetter(int index) {
  return String.fromCharCode('a'.codeUnitAt(0) + index);
}