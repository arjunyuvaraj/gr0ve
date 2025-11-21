import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? value;
  final bool bottomBorder;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.bottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: bottomBorder
            ? Border(bottom: BorderSide(color: Colors.black.withAlpha(30)))
            : null,
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 12),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            value ?? "no data",
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimary.withAlpha(255),
            ),
          ),
        ],
      ),
    );
  }
}
