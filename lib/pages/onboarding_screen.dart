import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/components/custom_text_field.dart';
import 'package:gr0ve/services/authentication_service.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsetsGeometry.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Welcome to".capitalized, style: context.text.displaySmall),
              Text("Gr0ve".capitalized, style: context.text.displayMedium),
              const SizedBox(height: 24),
              CustomTextField(
                hintText: "What Should We Call You",
                controller: nameController,
                obscureText: false,
              ),
              const SizedBox(height: 16),
              CustomPrimaryButton(
                label: "Get Started".capitalized,
                onTap: () => AuthenticationService().onboardUser(
                  context,
                  nameController.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
