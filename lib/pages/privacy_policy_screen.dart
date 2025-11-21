import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/privacy_policy.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isSignedIn = user != null;

    Widget pageContent() {
      return Column(
        children: [
          CustomHeader(
            title: "Gr0ve".capitalized,
            subtitle: privacyPolicySections[0]["content"].toString(),
          ),

          if (!isSignedIn) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/landing");
              },
              child: const Text(
                "Back to Landing Page",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],

          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: privacyPolicySections.length - 1,
              itemBuilder: (context, rawIndex) {
                final index = rawIndex + 1;
                final section = privacyPolicySections[index];
                final title = section["title"] ?? "";
                final content = section["content"] ?? "";

                return Container(
                  margin: const EdgeInsets.only(bottom: 14, left: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.headlineSmall?.copyWith(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.45,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (isSignedIn) {
      return pageContent();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: pageContent(),
        ),
      ),
    );
  }
}
