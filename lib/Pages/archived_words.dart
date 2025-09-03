import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/widgets.dart';
import 'package:wordini/word_functions.dart';

class ArchivedWordsScreen extends ConsumerStatefulWidget {
  const ArchivedWordsScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  ArchivedWordsScreenState createState() => ArchivedWordsScreenState();
}

class ArchivedWordsScreenState extends ConsumerState<ArchivedWordsScreen> {
  @override
  Widget build(BuildContext context) {
    final Map words = ref.watch(archivedWordsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Words'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: words.length,
        itemBuilder: (context, index) {
          final MapEntry word = words.entries.elementAt(index);
          final Map firstWordDetails = getFirstData(words, word.key);
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Dismissible(
              key: ValueKey(word),
              dismissThresholds: const {
                DismissDirection.endToStart: 0.5,
                DismissDirection.startToEnd: 0.5,
              },
              background: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.blue,
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.restore, color: Colors.white),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.red.shade400,
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),



              confirmDismiss: (direction) async {
                // if (direction == DismissDirection.startToEnd) {
                // }
                return true;
              },

              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  debugPrint('Deleting word: ${word.key}');
                  ref.read(archivedWordsProvider.notifier).removeKey(word.key);
                } else if (direction == DismissDirection.startToEnd) {
                  debugPrint('Restoring word: ${word.key}');
                  ref.read(wordDataProvider.notifier).updateWord(word.key, word.value);
                  ref.read(archivedWordsProvider.notifier).removeKey(word.key);
                }
              },

              // Your original ListTile child remains the same
              child: ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      capitalise(word.key),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        getWordType(words[word.key]).join(' / '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: MWTaggedText(
                  (firstWordDetails['definitions']?.first?['definition']) ?? '',
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}