import 'package:flutter/material.dart';

class LoadingOverlay {
  late OverlayEntry _overlayEntry;

  void showLoadingOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry);
  }

  // Remove loading overlay
  void removeLoadingOverlay() {
    _overlayEntry.remove();
  }
}
void errorOverlay(context, String message) {
  var overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return _AnimatedErrorOverlay(
        message: message,
        onFinish: () => overlayEntry.remove(),
      );
    },
  );
  overlay.insert(overlayEntry);
}

class _AnimatedErrorOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onFinish;

  const _AnimatedErrorOverlay({
    required this.message,
    required this.onFinish,
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
    Future.delayed(const Duration(seconds: 2), () {
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
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.message),
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
    final matches = tagPattern.allMatches(text);

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: parseMerriamWebsterTags(buffer.toString()), style: currentStyle));
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
    final tagPattern = RegExp(r'\{([^|{}]+)\|([^|{}]*)\|([^|{}]*)\|?([^|{}]*)\}');
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
            // {sx|fashion||} → "fashion"
            return '— $part1';
          case 'a_link':
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
