import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SwipeableButton extends StatefulWidget {
  final String label;
  final VoidCallback onSwipe;
  final Color baseColor;

  const SwipeableButton({
    super.key,
    required this.label,
    required this.onSwipe,
    this.baseColor = AppColors.primary,
  });

  @override
  State<SwipeableButton> createState() => _SwipeableButtonState();
}

class _SwipeableButtonState extends State<SwipeableButton> {
  double _dragPosition = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dragLimit = constraints.maxWidth - 64;

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: widget.baseColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: widget.baseColor.withValues(alpha: 0.3)),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  _isFinished ? 'Completed' : widget.label,
                  style: TextStyle(
                    color: widget.baseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > dragLimit) _dragPosition = dragLimit;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isFinished) return;
                    if (_dragPosition > dragLimit * 0.8) {
                      setState(() {
                        _dragPosition = dragLimit;
                        _isFinished = true;
                      });
                      widget.onSwipe();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.baseColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
