import 'package:flutter/material.dart';
import 'package:wordini/Pages/word_details.dart';
import 'package:wordini/file_handling.dart';

class LoadingOverlay {
  final OverlayEntry _overlayEntry = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 255/2),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  );
  bool overlayOn = false;
  void showLoadingOverlay(BuildContext context) {
    if (overlayOn) return;
    Overlay.of(context).insert(_overlayEntry);
    overlayOn = true;
  }

  // Remove loading overlay
  void removeLoadingOverlay() {
    if (!overlayOn) return;
    _overlayEntry.remove();
    _overlayEntry.dispose();
    overlayOn = false;
  }
}

void messageOverlay(BuildContext context, String message, {Duration duration = const Duration(seconds: 2), Color color = Colors.red, Widget? content}) {
  var overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return _AnimatedErrorOverlay(
        message: message,
        onFinish: () => overlayEntry.remove(),
        duration: duration,
        color: color,
        content: content,
      );
    },
  );
  overlay.insert(overlayEntry);
}

class _AnimatedErrorOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onFinish;
  final Duration duration;
  final Color color;
  final Widget? content;

  const _AnimatedErrorOverlay({
    required this.message,
    required this.onFinish,
    required this.duration,
    required this.color,
    this.content,
    });

  @override
  State<_AnimatedErrorOverlay> createState() => _AnimatedErrorOverlayState();
}

class _AnimatedErrorOverlayState extends State<_AnimatedErrorOverlay>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  
  @override
  void initState() {
    super.initState();
    // Fade in
    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1.0;
      });
    });
    // Fade out after 2 seconds
    Future.delayed(widget.duration, () {
      setState(() {
        _opacity = 0.0;
      });
      // Remove after fade out
      Future.delayed(const Duration(milliseconds: 300), widget.onFinish);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 50,
      right: 50,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.content ?? Text(widget.message),
          ),
        ),
      ),
    );
  }
}

class MWTaggedText extends StatelessWidget {
  final String input;
  final TextStyle? style;

  const MWTaggedText(this.input, {super.key, this.style});

  List<InlineSpan> _parseMWTags(String text) {
    final spans = <InlineSpan>[];
    final tagPattern = RegExp(r'{(/?)(\w+)}');
    final buffer = StringBuffer();
    final styleStack = <TextStyle>[];
    var currentStyle = const TextStyle();
    int lastIndex = 0;
    text = parseMerriamWebsterTags(text);
    final matches = tagPattern.allMatches(text);

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text:buffer.toString(), style: currentStyle));
        buffer.clear();
      }
    }

    for (final match in matches) {
      final tagStart = match.start;
      final tagEnd = match.end;
      final tagName = match.group(2);
      final isClosing = match.group(1) == '/';

      // Add text before this tag
      if (lastIndex < tagStart) {
        buffer.write(text.substring(lastIndex, tagStart));
      }

      flushBuffer();

      if (!isClosing) {
        // Opening tag
        styleStack.add(currentStyle);
        currentStyle = _applyStyle(currentStyle, tagName!);
      } else {
        // Closing tag
        if (styleStack.isNotEmpty) {
          currentStyle = styleStack.removeLast();
        }
      }

      lastIndex = tagEnd;
    }

    // Add any trailing text
    if (lastIndex < text.length) {
      buffer.write(text.substring(lastIndex));
    }

    flushBuffer();

    return spans;
  }

  TextStyle _applyStyle(TextStyle base, String tag) {
    switch (tag) {
      case 'it':
        return base.merge(const TextStyle(fontStyle: FontStyle.italic));
      case 'b':
        return base.merge(const TextStyle(fontWeight: FontWeight.bold));
      case 'sc':
        return base.merge(const TextStyle(letterSpacing: 1.5));
      case 'sup':
        return base.merge(const TextStyle(fontFeatures: [FontFeature.superscripts()]));
      case 'inf':
        return base.merge(const TextStyle(fontSize: 10));
      case 'bc':
        return base; // will be handled inline with a colon
      default:
        return base;
    }
  }
  String parseMerriamWebsterTags(String input) {
    final tagPattern = RegExp(
      r'\{([^|{}]+)\|([^|{}]*)(?:\|([^|{}]*))?(?:\|([^|{}]*))?\}'
    );
    return input.replaceAllMapped(tagPattern, (match) {
      final type = match[1];
      final part1 = match[2];
      final part2 = match[3];
      final part3 = match[4];
      if (part1 != null) {
        switch (type) {
          case 'dxt':
            // {dxt|flower|flower|illustration} → "flower (see illustration)"
            return '$part1 (see $part3)';
          case 'sx':
            // {sx|fashion||} → "— fashion"
            return '— $part1';
          case 'Sx':
            // {Sx|fashion||} → "fashion"
            return '{it}$part1{/it}';
          case 'a_link':
            return part1;
          case 'd_link':
          case 'i_link':
          case 'et_link':
            // {a_link|word} → "word"
            return part1;
          case 'dx':
          case 'dx_def':
          case 'dx_ety':
            // {dx|word|label} → "word (label)"
            if (part2 != null) {
              return part2.isNotEmpty ? '$part1 ($part2)' : part1;
            }
          case 'mat':
            // {mat|word|label} → "word (label)"
            if (part2 != null) {
              return part2.isNotEmpty ? '$part1 ($part2)' : part1;
            }
          case 'ma':
            // {ma|word|label} → "word (label)"
            if (part2 != null) {
              return part2.isNotEmpty ? '$part1 ($part2)' : part1;
            }
          case 'wi':
            // {wi|word} → "word"
            return part1;
          case 'qword':
            // {qword|word} → "“word”"
            return '“$part1”';
          case 'gloss':
            // {gloss} → "(gloss)"
            return '(gloss)';
          case 'sup':
            // {sup|text} → "text"
            return part1;
          case 'inf':
            // {inf|text} → "text"
            return part1;
          case 'it':
            // {it|text} → "text"
            return part1;
          case 'sc':
            // {sc|text} → "text"
            return part1;
          case 'b':
            // {b} → ""
            return '';
          case 'bc':
            // {bc} → ":"
            return ':';
          case 'ds':
            // {ds|text} → "text"
            return part1;
          default:
            // Unknown tag, return the inner text if available
            return part1.isNotEmpty ? part1 : '';
        }
      }
      return input;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: _parseMWTags(input.replaceAll('{bc}', '')),
        style: style ?? DefaultTextStyle.of(context).style,
      ),
    );
  }
}

class AnimatedToggleSwitch extends StatefulWidget {
  final List<String> options;
  final Function(int) onToggle;
  final int initialIndex;

  const AnimatedToggleSwitch({
    super.key,
    required this.options,
    required this.onToggle,
    this.initialIndex = 0,
  });

  @override
  State<AnimatedToggleSwitch> createState() => _AnimatedToggleSwitchState();
}

class _AnimatedToggleSwitchState extends State<AnimatedToggleSwitch>
    with SingleTickerProviderStateMixin {
  late int selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: selectedIndex.toDouble(),
      end: selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    final newIndex = (selectedIndex + 1) % widget.options.length;
    
    setState(() {
      selectedIndex = newIndex;
    });
    
    // Update animation target
    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: newIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward(from: 0);
    widget.onToggle(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 33, 33, 33),
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 8) / widget.options.length;
            
            return Stack(
              children: [
                // Sliding background
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: _slideAnimation.value * itemWidth,
                      top: 0,
                      child: Container(
                        width: itemWidth,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Text labels
                Row(
                  children: List.generate(widget.options.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        child: AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            // Calculate how close this option is to being selected
                            final distance = (index - _slideAnimation.value).abs();
                            final isSelected = distance < 0.5;
                            
                            return AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 14,
                              ),
                              child: Text(
                                widget.options[index],
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AnimatedTick extends StatefulWidget {
  final Duration duration;
  final double size;
  final IconData icon;
  final Color color;
  const AnimatedTick({
    super.key,
    this.duration = const Duration(milliseconds: 750),
    this.size = 64, 
    this.icon = Icons.check_circle, 
    this.color = Colors.green,
  });

  @override
  State<AnimatedTick> createState() => AnimatedTickState();
}

class AnimatedTickState extends State<AnimatedTick> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  /// Call this method to show the animated tick
  void showTick() {
    setState(() {
      _visible = true;
    });
    _controller.forward(from: 0);
    Future.delayed(widget.duration, () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.icon,
              color: widget.color,
              size: widget.size,
            ),
          ),
        ),
      ],
    );
  }
}

dynamic showWordDetailsOverlay(String word, String partOfSpeech, BuildContext context) async{
  Map data = await readKey(word);
  Set allTags = await gatherTags();
  final bool? output;
  if (context.mounted){
    output = await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.grey.withOpacity(0.8)
              //   ),
              //   width: MediaQuery.of(context).size.width,
              //   height: MediaQuery.of(context).size.width,
              // ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  // border: Border.all(Color),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade700,
                      blurRadius: 6.5,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: WordDetails(
                  word: data, 
                  allTags: allTags,
                  activatedElements: ['synonyms'],
                  initialIndex: partOfSpeech,
                ), // Your custom widget here
              ),
            ],
          ),
        );
      },
    );
  }else {
    return false;
  }
  return output;
}
class GoalOptions extends StatefulWidget {
  final String goal;
  const GoalOptions({super.key, required this.goal});

  @override
  _GoalOptionsState createState() => _GoalOptionsState();
}

class _GoalOptionsState extends State<GoalOptions> {
  int _selectedIndex1 = 0; // First digit (tens)
  int _selectedIndex2 = 0; // Second digit (ones)
  final List<String> _options = List.generate(10, (index) => '$index'); // 0-9
  late FixedExtentScrollController _scrollController1;
  late FixedExtentScrollController _scrollController2;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController1 = FixedExtentScrollController(initialItem: 0);
    _scrollController2 = FixedExtentScrollController(initialItem: 0);
    _loadStartingPoint();
  }

  @override
  void dispose() {
    _scrollController1.dispose();
    _scrollController2.dispose();
    super.dispose();
  }

  // Load the starting point asynchronously
  Future<void> _loadStartingPoint() async {
    try {
      String startingPoint = await getStartingPoint();
      int value = int.tryParse(startingPoint) ?? 20;
      
      // Split the number into digits
      int tensDigit = (value ~/ 10) % 10; // Get tens digit (0-9)
      int onesDigit = value % 10; // Get ones digit (0-9)
      
      // Ensure indices are within bounds
      tensDigit = tensDigit.clamp(0, 9);
      onesDigit = onesDigit.clamp(0, 9);
      
      if (mounted) {
        setState(() {
          _selectedIndex1 = tensDigit;
          _selectedIndex2 = onesDigit;
          _isLoading = false;
        });
        
        // Jump to the correct positions after the widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController1.hasClients) {
            _scrollController1.jumpToItem(_selectedIndex1);
          }
          if (_scrollController2.hasClients) {
            _scrollController2.jumpToItem(_selectedIndex2);
          }
        });
      }
    } catch (e) {
      // Handle any errors during loading
      print('Error loading starting point: $e');
      if (mounted) {
        setState(() {
          _selectedIndex1 = 2; // Default to 20
          _selectedIndex2 = 0;
          _isLoading = false;
        });
      }
    }
  }

  Future<String> getStartingPoint() async {
    try {
      String value = (await readKey(widget.goal, path: 'settings', defaultValue: 20)).toString();
      return value;
    } catch (e) {
      print('Error reading key: $e');
      return '20'; // Return default value on error
    }
  }

  int get _combinedValue => (_selectedIndex1 * 10) + _selectedIndex2;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Goal Value',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // const Text('Goal'),
          const SizedBox(height: 10),
          
          // // Display current value
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   decoration: BoxDecoration(
          //     color: Colors.blue.withOpacity(0.1),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Text(
          //     'Current Goal: $_combinedValue',
          //     style: const TextStyle(
          //       fontSize: 16,
          //       fontWeight: FontWeight.bold,
          //       color: Colors.blue,
          //     ),
          //   ),
          // ),
          
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 30,
                        child: buildWheel(
                          _scrollController1,
                          (index) {
                            if (mounted) {
                              setState(() {
                                _selectedIndex1 = index;
                              });
                            }
                          },
                          _selectedIndex1,
                        ),
                      ),
                      
                      // Ones digit wheel - right next to tens wheel
                      SizedBox(
                        width: 30,
                        child: buildWheel(
                          _scrollController2,
                          (index) {
                            if (mounted) {
                              setState(() {
                                _selectedIndex2 = index;
                              });
                            }
                          },
                          _selectedIndex2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_combinedValue > 0){
                    try {
                      await writeKey(widget.goal, path: 'settings', _combinedValue);
                      if (context.mounted) {
                        Navigator.pop(context, _combinedValue);
                      }
                    } catch (e) {
                      debugPrint('Error saving goal: $e');
                      // Optionally show a snackbar or dialog with error message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving goal: $e')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildWheel(
    FixedExtentScrollController controller,
    Function(int) onSelectedItemChanged,
    int selectedIndex,
  ) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      onSelectedItemChanged: onSelectedItemChanged,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.005,
      diameterRatio: 1.5,
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          if (index < 0 || index >= _options.length) return null;

          final double opacity = 1.0 - (index - selectedIndex).abs() * 0.1;
          final adjustedOpacity = opacity.clamp(0.3, 1.0);

          return Opacity(
            opacity: adjustedOpacity,
            child: Center(
              child: Text(
                _options[index],
                style: TextStyle(
                  fontSize: 24,
                  color: selectedIndex == index 
                      ? Colors.blue 
                      : Colors.grey,
                  fontWeight: selectedIndex == index 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
        childCount: _options.length,
      ),
    );
  }
}