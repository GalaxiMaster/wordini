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
void errorOverlay(context, String s) {
  var overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return _AnimatedErrorOverlay(
        message: s,
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
