import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

class WordDetails extends StatefulWidget {
  final Map words;
  final String wordId;
  final bool addWordMode;
  const WordDetails({super.key, required this.words, required this.wordId, this.addWordMode = false});
  @override
  // ignore: library_private_types_in_public_api
  _WordDetailstate createState() => _WordDetailstate();
}

class _WordDetailstate extends State<WordDetails> {
  final PageController _controller = PageController(initialPage: 0);
  double currentPage = 0;
  bool editMode = false;
  late Map word;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _tagOverlayEntry;
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  late Set allTags = {};
  @override
  void initState() {
    super.initState();
    word = widget.words[widget.wordId];
    allTags = widget.words.values
        .expand((w) => w['tags'] ?? [])
        .toSet(); // Collect all unique tags from all words
    _controller.addListener(() {
      setState(() {
        currentPage = _controller.page ?? 0;
      });
    });
  }

  void _showTagPopup(BuildContext context) {
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
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
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
                                      hintText: "Add tag...",
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (value) {
                                      _addTag(value);
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () {
                                    _addTag(_tagController.text);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.white,),
                          ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: (allTags.isEmpty
                                ? [const ListTile(title: Text("No tags available", style: TextStyle(fontSize: 16)))]
                                : allTags.map((tag) => ListTile(
                                    leading: (word['tags'] ?? []).contains(tag) ? const Icon(Icons.check, size: 20) : null,
                                    title: Text(tag, style: const TextStyle(fontSize: 16)),
                                    onTap: () {
                                      setState(() {
                                        if ((word['tags'] ?? []).contains(tag)) {
                                          _removeTag(tag);
                                        } else {
                                          _addTag(tag);
                                        }
                                      });
                                      // _hideTagPopup();
                                      setPopupState(() {});

                                    },
                                  )).toList()),
                          )
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
  }

  void _addTag(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      allTags.add(value.trim()); // <-- update allTags
      word['tags'] ??= [];
      if (!word['tags'].contains(value.trim())) {
        word['tags'].add(value.trim());
        widget.words[widget.wordId] = word;
        writeData(widget.words, append: false);
      }
    });
  }

  void _removeTag(String tag) {
    setState(() {
      word['tags']?.remove(tag);
      widget.words[widget.wordId] = word;
      writeData(widget.words, append: false);
      // Optionally, update allTags if you want to remove tags not used anywhere
      // allTags = widget.words.values.expand((w) => w['tags'] ?? []).toSet();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Word Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        capitalise(word['word']),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CompositedTransformTarget(
                          link: _layerLink,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: -4,
                            children: [
                              for (var tag in word['tags'] ?? [])
                              Chip(
                                label: MWTaggedText(
                                  tag,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                backgroundColor: const Color.fromARGB(255, 19, 54, 79),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                side: BorderSide.none,
                                labelPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                              ),
                              if (editMode)
                              IconButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all<Color>(
                                      const Color.fromARGB(255, 19, 54, 79)),
                                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  _showTagPopup(context);
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            editMode = !editMode;
                          });
                        },
                        child: Icon(
                          editMode ? Icons.edit_outlined : Icons.edit,
                          size: 30,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Page indicator
                  SizedBox(
                    height: 10,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double width = constraints.maxWidth;
                        int totalPages = word['entries'].length;
                        double indicatorWidth = width / (totalPages == 0 ? 1 : totalPages);
            
                        return Stack(
                          children: [
                            Container(
                              width: width,
                              height: 4,
                              color: Colors.transparent,
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutQuint,
                              left: indicatorWidth * currentPage,
                              child: Container(
                                width: indicatorWidth,
                                height: 4,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // PageView for speech types
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: word['entries'].length,
                      itemBuilder: (context, index) {
                        MapEntry speechType = word['entries'].entries.toList().elementAt(index);
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Definition Section
                              Row(
                                children: [
                                  const Icon(Icons.menu_book_rounded, color: Colors.teal, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      capitalise(speechType.key),
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              editMode
                                  ? ReorderableListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      onReorder: (oldIndex, newIndex) {
                                        setState(() {
                                          if (newIndex > oldIndex) newIndex -= 1;
                                          final item = speechType.value['details'].removeAt(oldIndex);
                                          speechType.value['details'].insert(newIndex, item);
                                        });
                                      },
                                      itemCount: speechType.value['details'].length,
                                      itemBuilder: (context, index) {
                                        var entry = speechType.value['details'][index];
                                        return Column(
                                          key: ValueKey("definition_$index"),
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.drag_handle),
                                                MWTaggedText(
                                                  "${index + 1}.",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            // ReorderableListView for definitions within this numbered definition
                                            ReorderableListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              onReorder: (oldDefIndex, newDefIndex) {
                                                setState(() {
                                                  if (newDefIndex > oldDefIndex) newDefIndex -= 1;
                                                  final defItem = entry['definitions'].removeAt(oldDefIndex);
                                                  entry['definitions'].insert(newDefIndex, defItem);
                                                });
                                              },
                                              itemCount: entry['definitions'].length,
                                              itemBuilder: (context, defIndex) {
                                                var definition = entry['definitions'][defIndex];
                                                return ListTile(
                                                  key: ValueKey("def_${index}_$defIndex"),
                                                  dense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                  leading: const Icon(Icons.drag_indicator, size: 18),
                                                  title: Padding(
                                                    padding: EdgeInsets.zero, // Remove padding from the title
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        MWTaggedText(
                                                          "{b}${indexToLetter(defIndex)}){/b} ",
                                                          style: const TextStyle(fontSize: 16),
                                                        ),
                                                        SizedBox(width: 2,),
                                                        Expanded(
                                                          child: MWTaggedText(
                                                            "${definition[0]['definition']}",
                                                            style: const TextStyle(fontSize: 16),
                                                          )
                                                          // TextFormField(
                                                          //   initialValue: "{b}${indexToLetter(defIndex)}){/b} ${definition[0]['definition']}",
                                                          //   style: const TextStyle(fontSize: 16),
                                                          //   decoration: const InputDecoration(
                                                          //     isDense: true,
                                                          //     contentPadding: EdgeInsets.zero, // Remove padding inside the TextFormField
                                                          //     // border: InputBorder.none,
                                                          //   ),
                                                          //   onChanged: (val) {
                                                          //     setState(() {
                                                          //       entry['definitions'][defIndex][0]['definition'] = val;
                                                          //       widget.words[widget.wordId] = word;
                                                          //       writeData(widget.words, append: false);
                                                          //     });
                                                          //   },
                                                          // ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  trailing: PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, size: 18),
                                                    tooltip: "More actions",
                                                    onSelected: (value) {
                                                      if (value == 'delete') {
                                                        setState(() {
                                                          entry['definitions'].removeAt(defIndex);
                                                          widget.words[widget.wordId] = word;
                                                          writeData(widget.words, append: false);
                                                        });
                                                      }
                                                      else if (value == 'edit') {
                                                        // ADD edit screen
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit, size: 18, color: Colors.white),
                                                            SizedBox(width: 8),
                                                            Text('Edit'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Delete'),
                                                          ],
                                                        ),
                                                      ),
                                                      // Add more PopupMenuItem widgets here for more actions
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  : Column(
                                      children: speechType.value['details'].asMap().entries.map<Widget>((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              MWTaggedText(
                                                "${entry.key + 1}. ",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    for (var definition in entry.value['definitions'].asMap().entries)
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 4),
                                                        child: MWTaggedText(
                                                          "{b}${indexToLetter(definition.key)}){/b} ${definition.value[0]['definition']}", // Currently set to only show the first wording of it
                                                          style: const TextStyle(fontSize: 16),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              const SizedBox(height: 18),
                                                         // Synonyms Section
                              if (speechType.value['synonyms'] != null && speechType.value['synonyms'].isNotEmpty) ...[
                                Divider(),
                                Row(
                                  children: const [
                                    Icon(Icons.local_florist_rounded, color: Colors.green, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "Synonyms",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: speechType.value['synonyms'].entries
                                    .where((synonym) => synonym.key.toLowerCase() != word['word'].toLowerCase())
                                    .map<Widget>(
                                      (synonym) => Chip(
                                        label: MWTaggedText(
                                          capitalise(synonym.key),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        backgroundColor: const Color.fromARGB(255, 19, 54, 79),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        side: BorderSide.none,
                                      ),
                                    ).toList(),
                                ),
                              ],
                              // Etymology Section
                              if (speechType.value['etymology'] != null && speechType.value['etymology'].isNotEmpty) ...[
                                Divider(),
                                Row(
                                  children: const [
                                    Icon(Icons.biotech, color: Colors.amber, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "Etymology",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 17),
                                  child: MWTaggedText(
                                    speechType.value['etymology'],
                                    style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              // Quotes Section
                              if (speechType.value['quotes'] != null && speechType.value['quotes'].isNotEmpty) ...[
                                Divider(),
                                Row(
                                  children: const [
                                    Icon(Icons.format_quote_rounded, color: Colors.lightBlue, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "Quotes",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                for (var quote in speechType.value['quotes']) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.blue.shade300,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      child: MWTaggedText(
                                        '"${quote['t']}"\n - {it}${quote['aq']['auth']} (${quote['aq']['aqdate']}){/it}',
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (widget.addWordMode)
              Positioned(
                left: 50,
                right: 50,
                bottom: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 16, 38, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

