import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/word_details.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

enum TagPopupType{
  type,
  tag,
  sortBy,
  sortOrder,
}
class BoxDetails {
  final String text;
  final LayerLink layerLink;
  final Function onClick;
  final TagPopupType type;

  BoxDetails({
    required this.text,
    required this.layerLink,
    required this.onClick,
    required this.type,
  });
}

class WordList extends StatefulWidget {
  const WordList({super.key});
  @override
  WordListState createState() => WordListState();
}

class WordListState extends State<WordList> {
  late Future<Map<String, dynamic>> _wordsFuture;
  String searchTerm = '';
  Map filters = {
    'wordTypes': [],
    'wordTypeMode': 'any',
    'selectedTags': <String>{},
    'selectedTagsMode': 'any',
    'sortBy': 'Alphabetical',
    'sortOrder':'Ascending',
  };
  bool _showBar = false;

  OverlayEntry? _tagOverlayEntry;
  final TextEditingController _tagController = TextEditingController();
  final LayerLink _typeLayerLink = LayerLink();
  final LayerLink _tagLayerLink = LayerLink();
  final LayerLink _sortByLayerLink = LayerLink();
  final LayerLink _sortOrderLayerLink = LayerLink();

  final FocusNode _tagFocusNode = FocusNode();
  
  late Set allTags;
  late Set allTypes;
  @override
  void initState() {
    super.initState();
    _wordsFuture = readData();
  }
  void _showTagPopup(BuildContext context, TagPopupType tagMode) {
    if (_tagOverlayEntry != null) return;

    final overlay = Overlay.of(context);
    _tagController.clear();

    final bool isTag = tagMode == TagPopupType.tag;

    final LayerLink link = switch (tagMode) {
      TagPopupType.type => _typeLayerLink,
      TagPopupType.tag => _tagLayerLink,
      TagPopupType.sortBy => _sortByLayerLink,
      TagPopupType.sortOrder => _sortOrderLayerLink,
    };

    final Offset offset = switch (tagMode) {
      TagPopupType.type => const Offset(-10, 50),
      TagPopupType.tag => const Offset(-100, 50),
      TagPopupType.sortBy => const Offset(-20, 50),
      TagPopupType.sortOrder => const Offset(-20, 50),
    };

    _tagOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideTagPopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: offset,
            child: StatefulBuilder(
              builder: (context, setPopupState) {
                final children = switch (tagMode) {
                  TagPopupType.tag || TagPopupType.type => [
                    _buildSearchBar(setPopupState, isTag),
                    _buildToggleSwitch(setPopupState, isTag),
                    const Divider(color: Colors.white),
                    _buildListItems(setPopupState, isTag),
                  ],
                  TagPopupType.sortBy => [
                    _buildTwoOptionSelector(
                      options: const ['Alphabetical', 'Date Added'],
                      selected: filters['sortBy'],
                      onSelected: (value) {
                        filters['sortBy'] = value;
                        setPopupState(() {});
                      },
                    )
                  ],
                  TagPopupType.sortOrder => [
                    _buildTwoOptionSelector(
                      options: const ['Ascending', 'Descending'],
                      selected: filters['sortOrder'],
                      onSelected: (value) {
                        filters['sortOrder'] = value;
                        setPopupState(() {});
                      },
                    )
                  ],
                };

                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: children,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    overlay.insert(_tagOverlayEntry!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tagFocusNode.canRequestFocus) {
        _tagFocusNode.requestFocus();
      }
    });
  }

  Widget _buildListItems(void Function(void Function()) setState, bool isTag) {
    final Set items = isTag ? allTags : allTypes;
    final filterKey = isTag ? 'selectedTags' : 'wordTypes';
    final selected = filters[filterKey];

    if (items.isEmpty) {
      return const ListTile(
        title: Text("No items available", style: TextStyle(fontSize: 16)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        final isSelected = selected.contains(item);
        return ListTile(
          leading: isSelected ? const Icon(Icons.check, size: 20) : null,
          title: Text(item, style: const TextStyle(fontSize: 16)),
          onTap: () {
            if (isSelected) {
              selected.remove(item);
            } else {
              selected.add(item);
            }
            setState(() {});
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildTwoOptionSelector({
    required List<String> options,
    required String selected,
    required void Function(String) onSelected,
  }) {
    return Column(
      children: options.map((option) {
        final isSelected = selected == option;
        return ListTile(
          leading: isSelected ? const Icon(Icons.check, size: 20) : null,
          title: Text(option, style: const TextStyle(fontSize: 16)),
          onTap: () => onSelected(option),
        );
      }).toList(),
    );
  }
  
  Widget _buildSearchBar(void Function(void Function()) setState, bool isTag) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tagController,
              focusNode: _tagFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: isTag ? "Search tag..." : "Search type...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) {},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(void Function(void Function()) setState, bool isTag) {
    final key = isTag ? 'selectedTagsMode' : 'wordTypeMode';
    return AnimatedToggleSwitch(
      options: const ['Any', 'All'],
      initialIndex: filters[key] == 'any' ? 0 : 1,
      onToggle: (index) {
        filters[key] = index == 0 ? 'any' : 'all';
        setState(() {});
      },
    );
  }

  void _hideTagPopup() {
    _tagOverlayEntry?.remove();
    _tagOverlayEntry = null;
    setState(() {});
  }
  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
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

        List filteredWords = words.entries.where((word) { // all word filtering logic here
          final lowerWord = word.key.toLowerCase();
          final searchLower = searchTerm.toLowerCase();

          // Search filter
          if (!lowerWord.contains(searchLower)) return false;

          // Type filter
          final selectedTypes = (filters['wordTypes'] as List).map((e) => e.toLowerCase()).toList();
          final wordTypes = getWordType(word.value).map((e) => e.toLowerCase()).toList();
          final typeModeAll = filters['wordTypeMode'] == 'all';

          final matchesType = selectedTypes.isEmpty ||
              (typeModeAll
                  ? selectedTypes.every(wordTypes.contains)
                  : selectedTypes.any(wordTypes.contains));

          if (!matchesType) return false;

          // Tag filter
          final selectedTags = filters['selectedTags'];
          final wordTags = (word.value['tags'] ?? <String>[]).cast<String>().toSet();
          final tagModeAny = filters['selectedTagsMode'] == 'any';

          final matchesTags = selectedTags.isEmpty ||
              (tagModeAny
                  ? wordTags.intersection(selectedTags).isNotEmpty
                  : wordTags.containsAll(selectedTags));

          return matchesTags;
        }).toList();
        
        // Sorting the list
        switch (filters['sortBy']){
          case 'Alphabetical':
            filteredWords.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
          case 'Date Added':
            filteredWords.sort((a, b) => DateTime.parse(a.value['dateAdded']).compareTo(DateTime.parse(b.value['dateAdded'])));
        }
        if (filters['sortOrder'] == 'Descending'){
          filteredWords = filteredWords.reversed.toList();
        }

        allTags = words.values
          .expand((w) => w['tags'] ?? [])
          .toSet();
        allTypes = words.values
          .expand((w) => w['entries'].keys.toList() ?? [])
          .toSet();
        return Column(
          // mainAxisSize: MainAxisSize.min,
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
              constraints: BoxConstraints(
                minHeight: 10,
                maxHeight: _showBar ? 150 : 10, // Animate between 10 and 200
              ),
              child: _showBar
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  boxesWithHeading(
                    'Filtering',
                    [
                      BoxDetails(
                        text: 'Types', 
                        layerLink: _typeLayerLink, 
                        onClick: () => _showTagPopup(context, TagPopupType.type), 
                        type: TagPopupType.type
                      ),
                      BoxDetails(
                        text: 'Tags', 
                        layerLink: _tagLayerLink, 
                        onClick: () => _showTagPopup(context, TagPopupType.tag), 
                        type: TagPopupType.tag
                      ),
                    ],
                    context,
                  ),
                  boxesWithHeading(
                    'Sorting',
                    [
                      BoxDetails(
                        text: 'Sort By', 
                        layerLink: _sortByLayerLink, 
                        onClick: () => _showTagPopup(context, TagPopupType.sortBy), 
                        type: TagPopupType.sortBy
                      ),
                      BoxDetails(
                        text: 'Sort Order', 
                        layerLink: _sortOrderLayerLink, 
                        onClick: () => _showTagPopup(context, TagPopupType.sortOrder), 
                        type: TagPopupType.sortOrder
                      ),
                    ],
                    context,
                  ),
                  SizedBox(height: 10,)
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
                    final String word = filteredWords[index].value['word'];
                    final Map firstWordDetails = getFirstData(words, word);
                    return InkWell(
                      onLongPress: () async {
                        deleteKey(word);
                        setState(() {
                          words.remove(word); 
                        });
                      },
                      onTap: () async{
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WordDetails(word: words[word], allTags: allTags),
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
                          firstWordDetails['shortDefs'].isNotEmpty ? firstWordDetails['shortDefs'].first : firstWordDetails['definitions'].first.first['definition'] ,
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

  Widget boxesWithHeading(String heading, List<BoxDetails> boxes, BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            heading,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (BoxDetails box in boxes)
            CompositedTransformTarget(
              link: box.layerLink,
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
                onPressed: ()=> box.onClick(),
                child: Text(box.text),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Map getFirstData(Map words, String word) {
    Map entries = words[word]['entries']; // ?.first?.value['details']?.first
    for (MapEntry entry in entries.entries){
      for (Map detailEntry in entry.value['details']){
        return detailEntry;
      }
    }
    return {};
  }
}