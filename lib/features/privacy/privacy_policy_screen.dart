import 'package:gr0ve/core/utilities/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/core/utilities/extensions/context_extensions.dart';
import 'package:gr0ve/features/privacy/privacy_policy.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CustomHeader(
                title: "Gr0ve".capitalized,
                subtitle: privacyPolicySections[0]["content"].toString(),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: privacyPolicySections.length - 1,
                  itemBuilder: (context, rawIndex) {
                    final index = rawIndex + 1;
                    final section = privacyPolicySections[index];
                    final title = section["title"] ?? "";
                    final content = section["content"] ?? "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: colors.onSurface.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            content,
                            style: context.text.bodyMedium?.copyWith(
                              height: 1.5,
                              color: colors.onSurface.withAlpha(220),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
