import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/components/custom_secondary_button.dart';
import 'package:gr0ve/components/custom_text_field.dart';
import 'package:gr0ve/services/authentication_service.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
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
                hintText: "Email",
                controller: emailController,
                obscureText: false,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Password",
                controller: passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomPrimaryButton(
                label: "Login".capitalized,
                onTap: () => AuthenticationService().signInWithEmail(
                  context,
                  emailController.text,
                  passwordController.text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CustomSecondaryButton(
                    label: "Google".capitalized,
                    onTap: () =>
                        AuthenticationService().signInWithGoogle(context),
                  ),
                  const SizedBox(width: 8),
                  CustomSecondaryButton(
                    label: "Apple".capitalized,
                    onTap: () =>
                        AuthenticationService().signInWithApple(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
