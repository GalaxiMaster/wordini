import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/word_details.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/word_functions.dart';
class WordList extends StatefulWidget {
  WordList({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _WordListState createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late Future<Map> _wordsFuture;

  @override
  void initState() {
    super.initState();
    _wordsFuture = readData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map>(
      future: _wordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        Map words = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: words.length,
            itemBuilder: (context, index) {
              final word = words.keys.elementAt(index);
              return InkWell(
                onLongPress: () async {
                  deleteWord(word);
                  setState(() {
                    words.remove(word); 
                  });
                },
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordDetails(word: words[word]),
                  ),
                ),
                child: ListTile(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        capitalise(word),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        getWordType(words[word]).join(' / '),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    words[word]['definitions'][0]['definition'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
