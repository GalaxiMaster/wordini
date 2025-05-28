import 'package:flutter/material.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

class WordDetails extends StatefulWidget {
  final Map word;
  final bool addWordMode;
  const WordDetails({super.key, required this.word, this.addWordMode = false});
  @override
  // ignore: library_private_types_in_public_api
  _WordDetailstate createState() => _WordDetailstate();
}

class _WordDetailstate extends State<WordDetails> {
  final PageController _controller = PageController(
    initialPage: 0,
  );
  double currentPage = 0;
  bool editMode = false; 

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        currentPage = _controller.page ?? 0;
      });
    });
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
                        capitalise(widget.word['word']),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
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
                        int totalPages = widget.word['entries'].length;
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
                      itemCount: widget.word['entries'].length,
                      itemBuilder: (context, index) {
                        MapEntry speechType = widget.word['entries'].entries.toList().elementAt(index);
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
                              editMode ? ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  onReorder: (oldIndex, newIndex) {
                                    setState(() {
                                      // ADD perma move
                                      if (newIndex > oldIndex) newIndex -= 1;
                                      final item = speechType.value.removeAt(oldIndex);
                                      speechType.value.insert(newIndex, item);
                                    });
                                  },
                                  itemCount: speechType.value.length,
                                  itemBuilder: (context, index) {
                                    var entry = speechType.value[index];
                                    return ListTile(
                                      key: ValueKey("definition_$index"),
                                      leading: const Icon(Icons.drag_handle),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (var definition in entry['definitions'].asMap().entries)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: MWTaggedText(
                                                "{b}${indexToLetter(definition.key)}){/b} ${definition.value[0]['definition']}",
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Column(
                                  children: speechType.value.asMap().entries.map<Widget>((entry) {
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
                                                      "{b}${indexToLetter(definition.key)}){/b} ${definition.value[0]['definition']}",
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
                              if (speechType.value[0]['synonyms'] != null && speechType.value[0]['synonyms'].isNotEmpty) ...[
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
                                  children: speechType.value[0]['synonyms'].entries
                                    .where((synonym) => synonym.key.toLowerCase() != widget.word['word'].toLowerCase())
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
                              if (speechType.value[0]['etymology'] != null && speechType.value[0]['etymology'].isNotEmpty) ...[
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
                                    speechType.value[0]['etymology'],
                                    style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              // Quotes Section
                              if (speechType.value[0]['quotes'] != null && speechType.value[0]['quotes'].isNotEmpty) ...[
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
                                for (var quote in speechType.value[0]['quotes']) ...[
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

