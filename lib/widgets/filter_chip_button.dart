import 'package:flutter/material.dart';

class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB45A30);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF2C3539),
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}