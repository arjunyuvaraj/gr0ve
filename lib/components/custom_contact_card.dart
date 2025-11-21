import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

// ignore: must_be_immutable
class CustomContactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  GestureTapCallback? onTap = () {};
  CustomContactCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12, width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: context.text.headlineSmall?.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
