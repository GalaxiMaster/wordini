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
  late Map organisedDetails;
  final PageController _controller = PageController(
    initialPage: 0,
  );
  double currentPage = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    organisedDetails = organiseToSpeechPart(widget.word['entries']);
    _controller.addListener(() {
      setState(() {
        currentPage = _controller.page ?? 0;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    // List synonyms = gatherSynonyms(widget.word);
    // List antonyms = gatherAntonyms(widget.word);
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capitalise(widget.word['word']),
                  style: TextStyle(fontSize: 24),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 100),
                  child: Divider(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 10,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double width = constraints.maxWidth;
                      int totalPages = organisedDetails.length;
                      double indicatorWidth = width / totalPages;
          
                      return Stack(
                        children: [
                          // Background track
                          Container(
                            width: width,
                            height: 4,
                            color: Colors.transparent,
                          ),
                          // Active indicator
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
                    itemCount: organisedDetails.length,
                    itemBuilder: (context, index){
                      MapEntry speechType = organisedDetails.entries.elementAt(index);
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              capitalise(speechType.key),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            for (var entry in speechType.value.asMap().entries)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key + 1}.',
                                  ),
                                  for (var definition in entry.value['definitions'])...[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5),
                                      child: MWTaggedText(
                                        '{b}${indexToLetter(entry.value['definitions'].indexOf(definition))}){/b} ${definition[0]['definition']}',
                                      ),
                                    ),
                                    SizedBox(height: 7.5,)
                                  ]
                                  // if (entry.value['example'] != null) 
                                  //   Padding(
                                  //     padding: const EdgeInsets.only(left: 5),
                                  //     child: Text(
                                  //       'Example: ${entry.value['example']}',
                                  //       style: const TextStyle(fontStyle: FontStyle.italic),
                                  //     ),
                                  //   )
                                ],
                              ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
          if (widget.addWordMode)
          Positioned(
            bottom: 10,
            left: 50,
            right: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 16, 38, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              onPressed: (){
                Navigator.pop(context, true);
              }, 
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              )
            ),
          ),
        ],
      ),
    );
  }

}

