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
              padding: const EdgeInsets.fromLTRB(16, 35, 16, 0),
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
                    // top: 5,
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () async{
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Filter Options'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Filter by word type',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      StatefulBuilder(
                                        builder: (context, setStateDialog) {
                                          return GestureDetector(
                                            onTap: (){
                                              setStateDialog(() {
                                                if (!(filters['wordTypeMode'] == 'U')) {
                                                  filters['wordTypeMode'] = 'U';
                                                } else {
                                                  filters['wordTypeMode'] = '∩';
                                                }
                                              });
                                            },
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: filters['wordTypeMode'] == 'U' ? Colors.orangeAccent : Colors.red,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  filters['wordTypeMode'],
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  )
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      )
                                    ],
                                  ),
                                  StatefulBuilder(
                                    builder: (context, setStateDialog) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          for (var type in ['noun', 'verb', 'adjective', 'adverb'])
                                            GestureDetector(
                                              onTap: (){
                                                setStateDialog(() {
                                                  if (!filters['wordTypes'].contains(type)) {
                                                    filters['wordTypes'].add(type);
                                                  } else {
                                                    filters['wordTypes'].remove(type);
                                                  }
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(6),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: filters['wordTypes'].contains(type) ? Colors.blue : Colors.grey[900],
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text(
                                                      type
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                            
                          },
                        );
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
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
                          words[word]['entries'].entries.first.value[0]['shortDefs'][0],
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
