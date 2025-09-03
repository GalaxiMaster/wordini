import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/file_handling.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Archived Words'),
                  content: const Text('Are you sure you want to permanently delete all archived words? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        resetData(null, ref, path: 'archivedWords');
                        Navigator.of(context).pop();
                      },
                      child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear All Archived Words',
          ),
        ],
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
                  ref.read(wordDataProvider.notifier).updateValue(word.key, word.value);
                  ref.read(archivedWordsProvider.notifier).removeKey(word.key);
                }
              },

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