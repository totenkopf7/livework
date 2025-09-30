// UPDATED: lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:livework_view/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:livework_view/providers/auth_provider.dart' as livework_auth;
import 'package:livework_view/helpers/localization_helper.dart'; // ADDED: Import localization helper

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 32),

              Text(
                translate(context, 'LiveWork View'), // UPDATED: Use translation
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                translate(
                    context, 'Sign in to continue'), // UPDATED: Use translation
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              // Consumer<LanguageProvider>(
              //     builder: (context, languageProvider, child) {
              //   return Text(
              //     translate(context, 'app_title'), // UPDATED: Use translation
              //     style: TextStyle(
              //       fontSize: 28,
              //       fontWeight: FontWeight.bold,
              //       color: AppColors.secondary,
              //     ),
              //   );
              // }),
              // const SizedBox(height: 8),
              // Consumer<LanguageProvider>(
              //     builder: (context, languageProvider, child) {
              //   return Text(
              //     translate(context,
              //         'sign_in_to_continue'), // UPDATED: Use translation
              //     style: TextStyle(
              //       fontSize: 12,
              //       // fontWeight: FontWeight.bold,
              //       color: Colors.grey,
              //     ),
              //   );
              // }),

              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: translate(
                                context, 'email'), // UPDATED: Use translation
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context,
                                  'please_enter_email'); // UPDATED: Use translation
                            }
                            if (!value.contains('@')) {
                              return translate(context,
                                  'please_enter_valid_email'); // UPDATED: Use translation
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: translate(context,
                                'password'), // UPDATED: Use translation
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context,
                                  'please_enter_password'); // UPDATED: Use translation
                            }
                            if (value.length < 6) {
                              return translate(context,
                                  'password_min_length'); // UPDATED: Use translation
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Consumer<livework_auth.LiveWorkAuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.isLoading) {
                              return const CircularProgressIndicator();
                            }

                            return ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  bool success = await authProvider.login(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );

                                  if (!success && authProvider.error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(authProvider.error!),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.background,
                                foregroundColor: AppColors.secondary,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              child: Consumer<LanguageProvider>(
                                  builder: (context, languageProvider, child) {
                                return Text(
                                  translate(context,
                                      'sign_in'), // UPDATED: Use translation
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                );
                              }), // UPDATED: Use translation
                            );
                          },
                        ),
                        if (context
                                .watch<livework_auth.LiveWorkAuthProvider>()
                                .error !=
                            null) ...[
                          const SizedBox(height: 16),
                          Text(
                            context
                                .watch<livework_auth.LiveWorkAuthProvider>()
                                .error!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
