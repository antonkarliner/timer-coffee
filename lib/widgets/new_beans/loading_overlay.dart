import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String label;

  const LoadingOverlay({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          color: theme.colorScheme.background,
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
