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
  String searchTerm = '';
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
        List filteredWords = words.keys.where((word) {
          return word.toLowerCase().contains(searchTerm.toLowerCase());
        }).toList();
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search for a word',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 87, 153, 239),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchTerm = value;
                  });
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                padding: EdgeInsets.zero, // Remove default padding
                shrinkWrap: true,
                itemCount: filteredWords.length,
                itemBuilder: (context, index) {
                  final word = filteredWords[index];
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
            ),
          ],
        );
      },
    );
  }
}
