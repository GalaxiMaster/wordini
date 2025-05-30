import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/word_details.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/word_functions.dart';
class WordList extends StatefulWidget {
  const WordList({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _WordListState createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late Future<Map> _wordsFuture;
  String searchTerm = '';
  Map filters = {
    'wordTypes': [],
    'wordTypeMode': 'U', // 'intersect': ∩ or 'union': ∪
  };
  bool _showBar = true;

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
          final matchesSearch = word.toLowerCase().contains(searchTerm.toLowerCase());
          final selectedTypes = filters['wordTypes'] as List;
          if (selectedTypes.isEmpty) return matchesSearch;
          final wordTypes = getWordType(words[word]).map((e) => e.toLowerCase()).toList();

          bool matchesType;
          if (filters['wordTypeMode'] == '∩') {
            // Intersect: must match ALL selected types
            matchesType = selectedTypes.every((type) => wordTypes.contains(type));
          } else {
            // Union: must match AT LEAST ONE selected type
            matchesType = selectedTypes.any((type) => wordTypes.contains(type));
          }
          return matchesSearch && matchesType;
        }).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 18, 18, 18),
              ),
              padding: const EdgeInsets.fromLTRB(16, 35, 16, 5),
              child: Stack(
                children: [
                  TextField(
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
                  Positioned(
                    right: 0,
                    top: 2.5,
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () async{
                        setState(() {
                          _showBar = !_showBar;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), // Animation duration
              curve: Curves.easeInOut,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 18, 18, 18),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              height: _showBar ? 60 : 10, // Animate between 60 and 5
              child: _showBar
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 50),
                            elevation: 0,
                          ),
                          onPressed: () {
                          },
                          child: const Text('Types'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 50),
                            elevation: 0,
                          ),
                          onPressed: () {
                          },
                          child: const Text('Tags'),
                        )
                      ],
                    )
                  : null,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  padding: EdgeInsets.zero, // Remove default padding
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
                          builder: (context) => WordDetails(words: words, wordId: word),
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
                            Expanded(
                              child: Text(
                                getWordType(words[word]).join(' / '),
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
                        subtitle: Text(
                          words[word]['entries'].entries.first.value['details'].first['shortDefs'][0],
                        ),
                      ),
                    );
                  },
                ),
              ),  
            ),
          ],
        );
      },
    );
  }
}
