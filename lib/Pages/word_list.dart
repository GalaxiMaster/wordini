import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/word_details.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';
class WordList extends StatefulWidget {
  const WordList({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _WordListState createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late Future<Map<String, dynamic>> _wordsFuture;
  String searchTerm = '';
  Map filters = {
    'wordTypes': [],
    'wordTypeMode': 'any',
    'selectedTags': <String>{},
    'selectedTagsMode': 'any',
  };
  bool _showBar = false;

  OverlayEntry? _tagOverlayEntry;
  final TextEditingController _tagController = TextEditingController();
  final LayerLink _typeLayerLink = LayerLink();
  final LayerLink _tagLayerLink = LayerLink();
  final FocusNode _tagFocusNode = FocusNode();
  
  late Set allTags;
  late Set allTypes;
  @override
  void initState() {
    super.initState();
    _wordsFuture = readData();
  }
  void _showTagPopup(BuildContext context, bool tagMode) {
    if (_tagOverlayEntry != null) return;
    final overlay = Overlay.of(context);
    _tagController.clear();
    _tagOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss when tapping outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _hideTagPopup();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The popup itself
          CompositedTransformFollower(
            link: tagMode ? _tagLayerLink : _typeLayerLink,
            showWhenUnlinked: false,
            offset: tagMode ? const Offset(-100, 50) : const Offset(-10, 50),
            child: StatefulBuilder(
              builder: (context,setPopupState) {
                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tagMode)...[
                            SizedBox(
                              height: 44,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _tagController,
                                      focusNode: _tagFocusNode,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: "Search tag...",
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (value) {
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () {
                                    },
                                  ),
                                ],
                              ),
                            ),
                            AnimatedToggleSwitch(
                              options: const ['Any', 'All'],
                              initialIndex: filters['selectedTagsMode'] == 'any' ? 0 : 1,
                              onToggle: (index) {
                                filters['selectedTagsMode'] = index == 0 ? 'any' : 'all';
                                setPopupState(() {});
                              },
                            ),
                            Divider(color: Colors.white,),
                            ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: (allTags.isEmpty
                                  ? [const ListTile(title: Text("No tags available", style: TextStyle(fontSize: 16)))]
                                  : allTags.map((tag) => ListTile(
                                      leading: (filters['selectedTags']).contains(tag) ? const Icon(Icons.check, size: 20) : null,
                                      title: Text(tag, style: const TextStyle(fontSize: 16)),
                                      onTap: () {
                                        if (!(filters['selectedTags']).contains(tag)) {
                                          filters['selectedTags'].add(tag);
                                        } else {
                                          filters['selectedTags'].remove(tag);
                                        }
                                        setPopupState(() {});
                                      },
                                    )).toList()),
                            )
                          ],
                          if (!tagMode)...[
                            SizedBox(
                              height: 44,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _tagController,
                                      focusNode: _tagFocusNode,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: "Search type...",
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (value) {
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () {
                                    },
                                  ),
                                ],
                              ),
                            ),
                            AnimatedToggleSwitch(
                              options: const ['Any', 'All'],
                              initialIndex: filters['wordTypeMode'] == 'any' ? 0 : 1,
                              onToggle: (index) {
                                filters['wordTypeMode'] = index == 0 ? 'any' : 'all';
                                setPopupState(() {});
                              },
                            ),
                            Divider(color: Colors.white,),
                            ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: (
                                allTypes.map((type) => ListTile(
                                  leading: (filters['wordTypes']).contains(type) ? const Icon(Icons.check, size: 20) : null,
                                  title: Text(type, style: const TextStyle(fontSize: 16)),
                                  onTap: () {
                                    if (!(filters['wordTypes']).contains(type)) {
                                      filters['wordTypes'].add(type);
                                    } else {
                                      filters['wordTypes'].remove(type);
                                    }
                                    setPopupState(() {});
                                  },
                                )).toList()),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );

    overlay.insert(_tagOverlayEntry!);

    // Focus after frame to ensure popup is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tagFocusNode.canRequestFocus) {
        _tagFocusNode.requestFocus();
      }
    });
  }

  void _hideTagPopup() {
    _tagOverlayEntry?.remove();
    _tagOverlayEntry = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _wordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        Map<String, dynamic> words = snapshot.data!;

        List filteredWords = words.keys.where((word) {
          final matchesSearch = word.toLowerCase().contains(searchTerm.toLowerCase());
          final selectedTypes = filters['wordTypes'] as List;
          final wordTypes = getWordType(words[word]).map((e) => e.toLowerCase()).toList();

          bool matchesType;
          if (filters['wordTypeMode'] == 'all') {
            matchesType = selectedTypes.isEmpty || selectedTypes.every((type) => wordTypes.contains(type.toLowerCase()));
          } else {
            matchesType = selectedTypes.isEmpty || selectedTypes.any((type) => wordTypes.contains(type.toLowerCase()));
          }

          final bool matchesTags;
          final wordTags = (words[word]['tags'] ?? []).cast<String>().toSet();
          if (filters['selectedTagsMode'] == 'any') {
            matchesTags = filters['selectedTags'].isEmpty || wordTags.intersection(filters['selectedTags'].cast<String>()).isNotEmpty;
          }
          else{
            matchesTags = filters['selectedTags'].isEmpty || wordTags.intersection(filters['selectedTags'].cast<String>()).length == filters['selectedTags'].length;
          }
          return matchesSearch && matchesType && matchesTags;
        }).toList();

        allTags = words.values
          .expand((w) => w['tags'] ?? [])
          .toSet();
        allTypes = words.values
          .expand((w) => w['entries'].keys.toList() ?? [])
          .toSet();
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
              height: _showBar ? 60 : 10, // Animate between 60 and 10
              child: _showBar
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CompositedTransformTarget(
                          link: _typeLayerLink,
                          child: ElevatedButton(
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
                              _showTagPopup(context, false);
                            },
                            child: const Text('Types'),
                          ),
                        ),
                        CompositedTransformTarget(
                          link: _tagLayerLink,
                          child: ElevatedButton(
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
                              _showTagPopup(context, true);
                            },
                            child: const Text('Tags'),
                          ),
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
                      onTap: () async{
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WordDetails(words: words, wordId: word),
                          ),
                        );
                        setState(() {
                          _wordsFuture = readData();
                        });
                      },
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