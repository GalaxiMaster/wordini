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