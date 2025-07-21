import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wordini/file_handling.dart';
import 'package:wordini/widgets.dart';
import 'package:wordini/word_functions.dart';

class WordDetails extends StatefulWidget {
  final bool addWordMode;
  final Map word;
  final Set allTags;
  final bool editModeState;
  final List activatedElements;
  final String? initialIndex;

  const WordDetails({
    super.key,
    required this.word,
    required this.allTags,
    this.addWordMode = false,
    this.editModeState = false,
    this.initialIndex,
    this.activatedElements = const [
      'synonyms',
      'etymology',
      'quotes',
      'quizHistory',
    ],
  });

  @override
  WordDetailsState createState() => WordDetailsState();
}

class WordDetailsState extends State<WordDetails> {
  late final PageController _controller;
  late double currentPage;
  bool editMode = false;
  late Map wordState;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _tagOverlayEntry;
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  late Set allTags;
  late Map inputs = {};

  @override
  void initState() {
    super.initState();
    wordState = Map.from(
      widget.word.map((key, value) {
        if (value is Map) return MapEntry(key, Map.from(value));
        if (value is List) return MapEntry(key, List.from(value));
        return MapEntry(key, value);
      }),
    );
    if (wordState.containsKey('entries')) {
      final entries = wordState['entries'] as Map;
      for (var speechPartKey in entries.keys) {
        final speechPartData = entries[speechPartKey] as Map;
        if (speechPartData.containsKey('definitions')) {
          if (speechPartData['definitions'] is List){
            speechPartData['definitions'] = organizeDefinitions(speechPartData['definitions']);
          }
        }
      }
    }

    allTags = widget.allTags;
    _controller = PageController(
      initialPage: widget.initialIndex != null
          ? getIndexOfSpeechPart(wordState, widget.initialIndex!)
          : 0,
    );
    currentPage = _controller.initialPage.toDouble();
    _controller
        .addListener(() => setState(() => currentPage = _controller.page ?? 0));
    getInputs();
    if (widget.editModeState) {
      editMode = widget.editModeState;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addSpeechPart();
      });
    }
  }

  int getIndexOfSpeechPart(Map word, String partOfSpeech) {
    int index = 0;
    for (var entry in word['entries'].keys.toList().asMap().entries) {
      if (entry.value == partOfSpeech) index = entry.key;
    }
    return index;
  }

  List<Map> _deconstructAndRenumber(Map organisedMap) {
    final List<Map> flatList = [];
    final sortedLevel1Keys = organisedMap.keys.cast<int>().toList()..sort();

    for (var level1Key in sortedLevel1Keys) {
      final node = organisedMap[level1Key];
      if (node.containsKey('definition')) {
        flatList.add({
          'sn': '$level1Key -1 -1',
          'definition': node['definition'],
          'example': node['example'] ?? [],
        });
      } else {
        _deconstructRecursive(node, level1Key.toString(), flatList);
      }
    }
    return flatList;
  }

  void _deconstructRecursive(Map node, String level1Key, List<Map> flatList) {
    final sortedLevel2Keys = node.keys.cast<String>().toList()..sort();

    for (var level2Key in sortedLevel2Keys) {
      final subNode = node[level2Key];
      final level2Num =
          (level2Key.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1).toString();

      if (subNode.containsKey('definition')) {
        flatList.add({
          'sn': '$level1Key $level2Num -1',
          'definition': subNode['definition'],
          'example': subNode['example'] ?? [],
        });
      } else {
        final sortedLevel3Keys = subNode.keys.cast<int>().toList()..sort();
        for (var level3Key in sortedLevel3Keys) {
          final leafNode = subNode[level3Key];
          if (leafNode.containsKey('definition')) {
            flatList.add({
              'sn': '$level1Key $level2Num $level3Key',
              'definition': leafNode['definition'],
              'example': leafNode['example'] ?? [],
            });
          }
        }
      }
    }
  }

  void _reorderSubDefinitions(List<dynamic> path, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      dynamic target = wordState;
      for (final key in path) {
        target = target[key];
      }
      Map reorderableMap = target as Map;

      final items = reorderableMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final movedItem = items.removeAt(oldIndex);
      items.insert(newIndex, movedItem);

      if (items.isEmpty) return;

      final bool isNumeric = items.first.key is int;
      final newMap = <dynamic, dynamic>{};
      for (int i = 0; i < items.length; i++) {
        final dynamic newKey =
            isNumeric ? (i + 1) : String.fromCharCode('a'.codeUnitAt(0) + i);
        newMap[newKey] = items[i].value;
      }

      dynamic parent = wordState;
      for (int i = 0; i < path.length - 1; i++) {
        parent = parent[path[i]];
      }
      parent[path.last] = newMap;

      saveWord();
    });
  }

  void _addSpeechPart() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController speechPartController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Add Speech Part'),
          content: TextField(
            controller: speechPartController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Speech Part (e.g. noun, verb, adjective)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final speechPart =
                    speechPartController.text.trim().toLowerCase();
                if (speechPart.isNotEmpty &&
                    !wordState['entries'].containsKey(speechPart)) {
                  setState(() {
                    wordState['entries'][speechPart] = {
                      'partOfSpeech': speechPart,
                      'selected': false,
                      'definitions': {},
                      'synonyms': {},
                      'etymology': '',
                      'quotes': [],
                    };
                    saveWord();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addDefinition(String speechPartKey) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController definitionController =
            TextEditingController();
        final TextEditingController exampleController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Definition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: definitionController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Definition',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: exampleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Example (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final definition = definitionController.text.trim();
                if (definition.isNotEmpty) {
                  setState(() {
                    final Map speechPartData =
                        wordState['entries'][speechPartKey];
                    final Map organisedDefinitions =
                        speechPartData['definitions'];
                    final int newKey = organisedDefinitions.isEmpty
                        ? 1
                        : (organisedDefinitions.keys.cast<int>().toList()
                              ..sort())
                            .last +
                            1;
                    organisedDefinitions[newKey] = { // Create SN
                      'definition': definition,
                      'example': exampleController.text.trim().isEmpty
                          ? []
                          : [exampleController.text.trim()]
                    };
                    saveWord();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addSubDefinition(List<dynamic> path) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController definitionController =
            TextEditingController();
        final TextEditingController exampleController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Sub-Definition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: definitionController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Definition',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: exampleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Example (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final definition = definitionController.text.trim();
                final example = exampleController.text.trim();
                if (definition.isNotEmpty) {
                  setState(() {
                    dynamic target = wordState;
                    for (final key in path) {
                      target = target[key];
                    }
                    Map node = target as Map;

                    final parentKey = path.last;
                    final bool keysAreNumeric = parentKey is String;

                    dynamic newKey;
                    if (keysAreNumeric) {
                      final int maxKey = node.keys.isEmpty
                          ? 0
                          : (node.keys.cast<int>().toList()..sort()).last;
                      newKey = maxKey + 1;
                    } else {
                      if (node.keys.isEmpty) {
                        newKey = 'a';
                      } else {
                        final String lastKey =
                            (node.keys.cast<String>().toList()..sort()).last;
                        newKey = String.fromCharCode(lastKey.codeUnitAt(0) + 1);
                      }
                    }

                    node[newKey] = {
                      'definition': definition,
                      'example': example.isEmpty ? [] : [example],
                    };
                    saveWord();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addSynonym(Map speechTypeValue) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController synonymController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Synonym'),
          content: TextField(
            controller: synonymController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Synonym',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final synonym = synonymController.text.trim();
                if (synonym.isNotEmpty) {
                  setState(() {
                    speechTypeValue['synonyms'] ??= {};
                    speechTypeValue['synonyms'][synonym] = {};
                    saveWord();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editEtymology(Map speechTypeValue) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController etymologyController =
            TextEditingController(text: speechTypeValue['etymology'] ?? '');
        return AlertDialog(
          title: const Text('Edit Etymology'),
          content: TextField(
            controller: etymologyController,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Etymology',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => speechTypeValue['etymology'] =
                    etymologyController.text.trim());
                saveWord();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addQuote(Map speechTypeValue) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController quoteController = TextEditingController();
        final TextEditingController authorController = TextEditingController();
        final TextEditingController dateController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Quote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quoteController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Quote',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date/Year',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final quote = quoteController.text.trim();
                final author = authorController.text.trim();
                final date = dateController.text.trim();
                if (quote.isNotEmpty && author.isNotEmpty) {
                  setState(() {
                    speechTypeValue['quotes'] ??= [];
                    speechTypeValue['quotes'].add({
                      't': quote,
                      'aq': {
                        'auth': author,
                        'aqdate': date.isEmpty ? 'Unknown' : date,
                      },
                    });
                    saveWord();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSynonym(Map speechTypeValue, String synonym) => setState(() {
        speechTypeValue['synonyms']?.remove(synonym);
        saveWord();
      });

  void _deleteQuote(Map speechTypeValue, int index) => setState(() {
        speechTypeValue['quotes']?.removeAt(index);
        saveWord();
      });

  void _showTagPopup(BuildContext context) {
    if (_tagOverlayEntry != null) return;
    final overlay = Overlay.of(context);
    _tagController.clear();
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
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
            child: StatefulBuilder(
              builder: (context, setPopupState) => Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                                  onSubmitted: _addTag,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () => _addTag(_tagController.text),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white),
                        ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: (allTags.isEmpty
                              ? [
                                  const ListTile(
                                    title: Text(
                                      "No tags available",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ]
                              : allTags
                                  .map(
                                    (tag) => ListTile(
                                      leading: (wordState['tags'] ?? [])
                                              .contains(tag)
                                          ? const Icon(Icons.check, size: 20)
                                          : null,
                                      title: Text(
                                        tag,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          (wordState['tags'] ?? [])
                                                  .contains(tag)
                                              ? _removeTag(tag)
                                              : _addTag(tag);
                                        });
                                        setPopupState(() {});
                                      },
                                    ),
                                  )
                                  .toList()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  void _hideTagPopup() {
    _tagOverlayEntry?.remove();
    _tagOverlayEntry = null;
  }

  void _addTag(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      allTags.add(value.trim());
      wordState['tags'] ??= [];
      if (!wordState['tags'].contains(value.trim())) {
        wordState['tags'].add(value.trim());
        saveWord();
      }
    });
  }

  void _removeTag(String tag) => setState(() {
        wordState['tags']?.remove(tag);
        saveWord();
      });

  void getInputs() async {
    final data = await readKey(wordState['word'], path: 'inputs');
    if (data != null) setState(() => inputs = data);
  }

  void saveWord({bool save = false}) {
    if ((!widget.addWordMode && wordState['word'] != null) || save) {
      final Map wordToSave = {
        ...wordState,
        'entries': Map.from(wordState['entries'].map((key, value) {
          return MapEntry(key, Map.from(value));
        })),
      };

      final entries = wordToSave['entries'] as Map;
      for (var speechPartKey in entries.keys) {
        final speechPartData = entries[speechPartKey];
        if (speechPartData.containsKey('definitions')) {
          speechPartData['definitions'] = _deconstructAndRenumber(speechPartData['definitions']);
        }
      }
      
      writeKey(wordState['word'], wordToSave);
    }
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                      Text(
                        capitalise(wordState['word']),
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
                              for (var tag in wordState['tags'] ?? [])
                                Chip(
                                  label: MWTaggedText(
                                    tag,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 19, 54, 79),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  side: BorderSide.none,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 3,
                                  ),
                                ),
                              if (editMode)
                                IconButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                      const Color.fromARGB(255, 19, 54, 79),
                                    ),
                                    shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  onPressed: () => _showTagPopup(context),
                                  icon: const Icon(Icons.add),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (editMode)
                        IconButton(
                          onPressed: _addSpeechPart,
                          icon: const Icon(Icons.add_box, size: 30),
                          tooltip: 'Add Speech Part',
                        ),
                      GestureDetector(
                        onTap: () => setState(() => editMode = !editMode),
                        child: Icon(
                          editMode ? Icons.edit_outlined : Icons.edit,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 10,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double width = constraints.maxWidth;
                        int totalPages = wordState['entries'].length;
                        double indicatorWidth =
                            width / (totalPages == 0 ? 1 : totalPages);
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
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: wordState['entries'].length,
                      itemBuilder: (context, index) {
                        MapEntry speechType = wordState['entries']
                            .entries
                            .toList()
                            .elementAt(index);
                        Map organisedDefinitions =
                            speechType.value['definitions'];
                        final organisedDefinitionEntries =
                            organisedDefinitions.entries.toList();

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book_rounded,
                                    color: Colors.teal,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      capitalise(speechType.key),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (editMode)
                                    IconButton(
                                      onPressed: () =>
                                          _addDefinition(speechType.key),
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.teal,
                                      ),
                                      tooltip: 'Add Definition',
                                    ),
                                  if (editMode)
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                      child: IconButton(
                                        key: ValueKey(
                                            speechType.value['selected']),
                                        onPressed: () {
                                          setState(() {
                                            if (speechType.value['selected'] == null) return;
                                            speechType.value['selected'] =
                                                !speechType.value['selected'];
                                            saveWord();
                                          });
                                        },
                                        icon: Icon(
                                          speechType.value?['selected'] ?? false
                                              ? Icons.check
                                              : Icons.close,
                                          color: speechType.value?['selected']?? false
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (editMode)
                                ReorderableListView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) {
                                    setState(() {
                                      if (newIndex > oldIndex) newIndex -= 1;
                                      final items =
                                          organisedDefinitions.entries.toList();
                                      final movedItem =
                                          items.removeAt(oldIndex);
                                      items.insert(newIndex, movedItem);
                                      final Map<dynamic, dynamic>
                                          newOrganisedMap = {};
                                      for (int i = 0; i < items.length; i++) {
                                        newOrganisedMap[i + 1] = items[i].value;
                                      }
                                      speechType.value['definitions'] =
                                          newOrganisedMap;
                                      saveWord();
                                    });
                                  },
                                  children: [
                                    for (int i = 0;i < organisedDefinitionEntries.length; i++)
                                      Column(
                                        key: ValueKey("definition_${organisedDefinitionEntries[i].key}"),
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              ReorderableDragStartListener(
                                                index: i,
                                                child: const Padding(
                                                  padding: EdgeInsets.only(
                                                    right: 8.0,
                                                    top: 2.0,
                                                    bottom: 2.0,
                                                  ),
                                                  child: Icon(Icons.drag_indicator),
                                                ),
                                              ),
                                              MWTaggedText(
                                                "${organisedDefinitionEntries[i].key}. ",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (organisedDefinitionEntries[i].value.containsKey('definition'))
                                              Expanded(
                                                child: _buildDefinitionLayer(
                                                  organisedDefinitionEntries[i].value,
                                                  [
                                                    'entries',
                                                    speechType.key,
                                                    'definitions',
                                                    organisedDefinitionEntries[i].key,
                                                  ],
                                                  isEditMode: true,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (!organisedDefinitionEntries[i].value.containsKey('definition'))
                                                IconButton(
                                                  onPressed: () => _addSubDefinition([
                                                    'entries',
                                                    speechType.key,
                                                    'definitions',
                                                    organisedDefinitionEntries[i].key,
                                                  ]),
                                                  icon: const Icon(Icons.add),
                                                  tooltip: "Add Sub-definition",
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                            ],
                                          ),
                                          if (!organisedDefinitionEntries[i].value.containsKey('definition'))
                                          Padding(
                                            padding: const EdgeInsets.only(left: 16.0),
                                            child: Expanded(
                                              child: _buildDefinitionLayer(
                                                organisedDefinitionEntries[i].value,
                                                [
                                                  'entries',
                                                  speechType.key,
                                                  'definitions',
                                                  organisedDefinitionEntries[i].key,
                                                ],
                                                isEditMode: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                )
                              else
                                Column(
                                  children: organisedDefinitions.entries
                                      .map<Widget>((entry) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          MWTaggedText(
                                            "${entry.key}. ",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildDefinitionLayer(
                                              entry.value,
                                              [
                                                'entries',
                                                speechType.key,
                                                'definitions',
                                                entry.key
                                              ],
                                              isEditMode: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 18),
                              if (((speechType.value['synonyms']?.isNotEmpty ??
                                          false) ||
                                      editMode) &&
                                  widget.activatedElements
                                      .contains('synonyms')) ...[
                                const Divider(),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_florist_rounded,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Synonyms",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (editMode) ...[
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () =>
                                            _addSynonym(speechType.value),
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Add Synonym',
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: (speechType.value['synonyms'] ??
                                          {})
                                      .entries
                                      .where((synonym) =>
                                          synonym.key.toLowerCase() !=
                                          wordState['word'].toLowerCase())
                                      .map<Widget>((synonym) => editMode
                                          ? Chip(
                                              label: MWTaggedText(
                                                capitalise(synonym.key),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                255,
                                                19,
                                                54,
                                                79,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              side: BorderSide.none,
                                              deleteIcon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              onDeleted: () => _deleteSynonym(
                                                speechType.value,
                                                synonym.key,
                                              ),
                                            )
                                          : Chip(
                                              label: MWTaggedText(
                                                capitalise(synonym.key),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                255,
                                                19,
                                                54,
                                                79,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              side: BorderSide.none,
                                            ))
                                      .toList(),
                                ),
                              ],
                              if (((speechType.value['etymology']?.isNotEmpty ?? false) || editMode) &&
                                  widget.activatedElements.contains('etymology')) ...[
                                const Divider(),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.biotech,
                                      color: Colors.amber,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Etymology",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (editMode) ...[
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () => _editEtymology(speechType.value),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.amber,
                                        ),
                                        tooltip: 'Edit Etymology',
                                      ),
                                    ],
                                  ],
                                ),
                                if (speechType.value['etymology'] ?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 17,
                                      vertical: 8,
                                    ),
                                    child: MWTaggedText(
                                      speechType.value['etymology'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                              ],
                              if (((speechType.value['quotes']?.isNotEmpty ?? false) ||editMode) &&
                                  widget.activatedElements.contains('quotes')) ...[
                                const Divider(),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.format_quote_rounded,
                                      color: Colors.lightBlue,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Quotes",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (editMode) ...[
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () =>
                                            _addQuote(speechType.value),
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.lightBlue,
                                        ),
                                        tooltip: 'Add Quote',
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                for (int i = 0; i < (speechType.value['quotes'] ?? []).length; i++) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.blue.shade300,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: MWTaggedText(
                                              '"${speechType.value['quotes'][i]['t']}"\n - {it}${speechType.value['quotes'][i]['aq']['auth']} (${speechType.value['quotes'][i]['aq']['aqdate']}){/it}',
                                            ),
                                          ),
                                          if (editMode)
                                            IconButton(
                                              onPressed: () => _deleteQuote(
                                                speechType.value,
                                                i,
                                              ),
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              tooltip: 'Delete Quote',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              if (((inputs[speechType.value['partOfSpeech']]?.isNotEmpty ?? false) || editMode) &&
                                  widget.activatedElements.contains('quizHistory')) ...[
                                const Divider(),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.history,
                                      color: Color.fromARGB(255, 7, 255, 48),
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Quiz History",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  itemCount: inputs[speechType.value['partOfSpeech']]?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final Map entry = inputs[speechType
                                        .value['partOfSpeech']][index];
                                    if (!entry.containsKey('guess') ||
                                        entry['guess'] == null) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 156, 2, 2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'SKIPPED',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                                Text(
                                                  ' — ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(entry['date']))}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                if (editMode)
                                                  IconButton(
                                                    onPressed: () => setState(
                                                      () => inputs[speechType.value['partOfSpeech']].removeAt(index),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.close,
                                                      size: 20,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 19, 54, 79),
                                          borderRadius:BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  entry['correct']
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: entry['correct']
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    entry['guess'],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                if (editMode)
                                                  IconButton(
                                                    onPressed: () => setState(
                                                      () => inputs[speechType.value['partOfSpeech']].removeAt(index),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.close,
                                                      size: 20,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ' — ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(entry['date']))}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
                    saveWord(save: true);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (Route<dynamic> route) => false,
                    );
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

  Widget _buildDefinitionLayer(Map layer, List<dynamic> path,
      {required bool isEditMode}) 
    {
    final parentLayer = path.sublist(0, path.length-1).fold(wordState, (current, key) => current[key]);

    if (layer.containsKey('definition')) {
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          if (!isEditMode) return;
          bool nesting = details.velocity.pixelsPerSecond.dx < 0 ? false : true;
          if (parentLayer.length > 1 && !nesting) return;
          setState((){
            adjustNesting(
              data: wordState[path[0]][path[1]][path[2]] as Map<int, dynamic>,
              definition: layer,
              nest: nesting,
            );
          });
        },
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                MWTaggedText(
                  "${layer['definition'] ?? ''}",
                  style: const TextStyle(fontSize: 16),
                ),
              if (layer['example'] != null)
                ...List<String>.from(layer['example']).map(
                  (example) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.blue.shade300,
                            width: 4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      child: MWTaggedText(capitalise(example)),
                    ),
                  ),
                ),
            ],
          ),
          trailing: editMode ? PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 18,
            ),
            tooltip: "More actions",
            onSelected: (value) {
              if (value == 'delete') {
                setState(() {
                  if (parentLayer.length == 1){
                    parentLayer.remove(path.last);
                    if (parentLayer.isEmpty){
                      Map nextLayer = {};
                      int i = 1;
                      while (nextLayer.isEmpty){
                        i++;
                        nextLayer = path.sublist(0, path.length-i).fold(wordState, (current, key) => current[key]);
                        int index = nextLayer.keys.toList().indexOf(path[path.length-i]);
                        if (nextLayer.length == 1){
                          i++;
                          nextLayer = path.sublist(0, path.length-i).fold(wordState, (current, key) => current[key]);
                          // nextLayer.remove(path[path.length-i]);
                        }
                        if (index != nextLayer.length-1){
                          for (int j = index + 1; j < nextLayer.length; j++) {
                            final key = nextLayer.keys.elementAt(j);
                            final newKey = key is int ? key - 1 : String.fromCharCode(key.codeUnitAt(0) - 1);

                            nextLayer[newKey] = nextLayer[key];

                            nextLayer.remove(key);
                          }
                        } else{
                          nextLayer.remove(path[path.length-i]);
                        }
                        // nextLayer.remove(path[path.length-i]);

                      }
                    }
                  } else{
                    int index = parentLayer.keys.toList().indexOf(path.last);
                    if (index != parentLayer.length-1){
                      for (int i = index + 1; i < parentLayer.length; i++) {
                        final key = parentLayer.keys.elementAt(i);
                        final newKey = key is int ? key - 1 : String.fromCharCode(key.codeUnitAt(0) - 1);
                        // final newSn = parentLayer[newKey]['sn'];
                        // if (parentLayer[key].containsKey)
                        // parentLayer[key]['sn'] = newSn;
                        parentLayer[newKey] = parentLayer[key];

                        parentLayer.remove(key);
                      }
                    } else{
                      parentLayer.remove(path.last);
                      debugPrint('removed');
                    }
                    // cascading deletions
                  }
                  saveWord();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ) : null,
        ),
      );
    }

    final entries = layer.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const SizedBox.shrink();

    if (!isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map<Widget>((entry) {
          final isNumeric = entry.key is int;
          final String prefix = isNumeric ? "${entry.key}. " : "{b}${entry.key}){/b} ";
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MWTaggedText(prefix, style: const TextStyle(fontSize: 16)),
                Expanded(
                  child: _buildDefinitionLayer(
                    entry.value,
                    [...path, entry.key],
                    isEditMode: false,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) => _reorderSubDefinitions(path, oldIndex, newIndex),
      children: [
        for (int i = 0; i < entries.length; i++)
          Row(
            key: ValueKey('${path.join('-')}-${entries[i].key}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding: EdgeInsets.only(
                    right: 8.0,
                    top: 15,
                  ),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: Colors.white54,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MWTaggedText(
                          entries[i].key is int
                              ? "${entries[i].key}. "
                              : "{b}${entries[i].key}){/b} ",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        if (!entries[i].value.containsKey('definition'))
                          IconButton(
                            onPressed: () => _addSubDefinition([...path, entries[i].key]),
                            icon: const Icon(Icons.add),
                            tooltip: "Add Sub-definition",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    _buildDefinitionLayer(
                      entries[i].value as Map,
                      [...path, entries[i].key],
                      isEditMode: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  bool adjustNesting({
    required Map<int, dynamic> data, 
    required Map definition,
    required bool nest
    }) { // function not happy if 'sn' isnt a key, which shouldnt happen, but if it does it crashes
    String sn = definition['sn'];
    List<String> parts = sn.split(' ');
    List path = parts.asMap().entries.map((entry) {
      int index = entry.key;
      String value = entry.value;
      int intValue = int.tryParse(value) ?? 0; 
      
      return index == 1 ? indexToLetter(intValue - 1) : intValue;
    }).toList();
    if (nest){ // ! case for nesting a definition
      if (!parts.contains('-1')){
        return false;
      }else {
        int index = parts.indexOf('-1');
        
        switch (index){
          case 1:
            // from 1 -> a
            definition['sn'] = '${parts[0]} 1 -1';
            data[path[0]] = {
              'a': definition,
            };
          case 2:
            // from a -> 1
            definition['sn'] = '${parts[0]} ${parts[1]} 1';
            data[path[0]][path[1]] = {
              1: definition
            };
          default: return false;
        }
      }
    }else{ // ! case for de-nesting a definition
      int count = parts.where((element) => element == '-1').length;
      if (count > 1){
        return false;
      } else{
        int index = parts.indexOf('-1');
        if (index == -1){
          // from 1 -> a
          definition['sn'] = '${parts[0]} ${parts[1]} -1';
          data[path[0]][path[1]] = definition;
        } else {
          // from a -> 1
          definition['sn'] = '${parts[0]} -1 -1';
          data[path[0]] = definition;
        }
      }
    }
    return true;
  }
}