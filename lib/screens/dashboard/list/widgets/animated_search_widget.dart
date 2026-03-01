import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';

class AnimatedSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String primaryPlaceholder;
  final String secondaryPlaceholder;
  final Duration switchDuration;

  const AnimatedSearchWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.primaryPlaceholder,
    required this.secondaryPlaceholder,
    this.switchDuration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedSearchWidget> createState() => _AnimatedSearchWidgetState();
}

class _AnimatedSearchWidgetState extends State<AnimatedSearchWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showPrimary = true;
  Timer? _switchTimer;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500), // Longer for fade effect
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Start slightly below
      end: const Offset(0, 0), // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start the switching timer
    _startSwitchTimer();

    // Listen to text field focus changes
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Stop animation when user starts typing
    if (widget.controller.text.isNotEmpty && !_isFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isFocused = true;
          });
          _stopAnimation();
        }
      });
    } else if (widget.controller.text.isEmpty && _isFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isFocused = false;
          });
          _startAnimation();
        }
      });
    }
  }

  void _startSwitchTimer() {
    _switchTimer = Timer.periodic(widget.switchDuration, (timer) {
      if (mounted && !_isFocused) {
        _switchText();
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  void _switchText() {
    if (!mounted) return;

    // Fade out current text
    _animationController.reverse().then((_) {
      if (mounted && !_isFocused) {
        setState(() {
          _showPrimary = !_showPrimary;
        });
        // Fade in new text
        _animationController.forward();
      }
    });
  }

  void _stopAnimation() {
    _switchTimer?.cancel();
    _animationController.stop();
  }

  void _startAnimation() {
    _animationController.forward();
    _startSwitchTimer();
  }

  @override
  void dispose() {
    _switchTimer?.cancel();
    _animationController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Stack(
        children: [
          // The actual TextField
          TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              prefixIcon: const Icon(
                Icons.search,
                color: kPrimaryColor,
              ),
              hintText: _isFocused ? 'Search by Name or Mobile Number' : '',
              //filled: true,
              //fillColor: kWhite,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(
                  color: kPrimaryColor,
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(
                  color: kPrimaryColor,
                  width: 1.0,
                ),
              ),
            ),
          ),

          // Animated placeholder overlay - positioned inside the search bar
          if (!_isFocused)
            Positioned(
              left: 50, // Adjust to match prefix icon width
              top: 0,
              bottom: 0,
              right: 10,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _showPrimary
                                ? widget.primaryPlaceholder
                                : widget.secondaryPlaceholder,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
