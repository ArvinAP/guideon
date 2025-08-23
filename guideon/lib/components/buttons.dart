import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220, // Matches design width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 255, 249, 175),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color.fromARGB(255, 21, 77, 113),
            fontFamily: 'Coiny',
          ),
        ),
      ),
    );
  }
}

class TransparentButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const TransparentButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, // Matches outlined button width
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 21, 77, 113),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color.fromARGB(255, 234, 239, 239),
            fontFamily: 'Coiny',
          ),
        ),
      ),
    );
  }
}
