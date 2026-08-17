import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/widgets.dart';
import 'package:wordini/word_functions.dart';

class FlashCardPage extends ConsumerStatefulWidget {
  const FlashCardPage({super.key});
  @override
  FlashCardPageState createState() => FlashCardPageState();
}

class FlashCardPageState extends ConsumerState<FlashCardPage> {
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(wordDataFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Cards'),
      ),
      body: asyncData.when(
        data: (words) {
          // final allTags = words.values.expand((w) => w['tags'] ?? []).toSet();
          // final allTypes = words.values
              // .expand((w) => w['entries'].keys.toList() ?? [])
              // .toSet();
          if (words.isEmpty) {
            return const Center(
              child: Text('No words available for flash cards.'),
            );
          }
          final List wordKeys = words.keys.toList()..shuffle();
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: words.length,
            itemBuilder:(context, index) {
              final String word = wordKeys[index];
              final firstWordDetails = getFirstData(words, word);
              return Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width*0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            capitalise(word),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            firstWordDetails['partOfSpeech'] != null
                                ? ' (${firstWordDetails['partOfSpeech']})'
                                : '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            )
                          ),
                          const SizedBox(height: 8),
                          MWTaggedText(firstWordDetails['definitions'] is List
                            ? ((firstWordDetails['definitions'] as List).elementAtOrNull(0) ?? {})['definition'] ??
                                ''
                            : '', textAlign: TextAlign.center)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '${index + 1} of ${words.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 125,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showWordDetailsOverlay(
                            word: words[word]['word'],
                            // partOfSpeech: words[word]['attributes']['partOfSpeech'],
                            context: context
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
          );
        },
        error: (err, stack) => Center(child: Text('Error loading data: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      )
    );
  }
}