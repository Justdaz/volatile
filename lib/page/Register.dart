import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:volatile/models/register_request.dart';
import 'package:volatile/page/Login.dart';
import 'package:volatile/routes.dart';
import 'package:volatile/widgets/error_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volatile/bloc/register_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  bool isObscure = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8D5C4),
                Color(0xFFD4C1B0),
                Color(0xFFC4B5A8),
              ],
            ),
          ),
        ),

        // Global blur — hanya satu BackdropFilter!
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.05)),
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Sign Up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 50),

                      _glassTextField(
                        controller: usernameController,
                        hintText: "Username",
                      ),

                      const SizedBox(height: 16),

                      _glassTextField(
                        controller: emailController,
                        hintText: "Email",
                      ),

                      const SizedBox(height: 16),

                      _glassTextField(
                        controller: passwordController,
                        hintText: "Password",
                        isPassword: true,
                        isObscure: isObscure,
                        onToggle: () => setState(() {
                          isObscure = !isObscure;
                        }),
                      ),

                      const SizedBox(height: 40),

                      BlocConsumer<RegisterBloc, SignupState>(
                        listener: (context, state) {
                          if (state is SignupSuccess) {
                            Navigator.pushReplacementNamed(
                                context, MyRoute.login.name);
                          } else if (state is SignupFailed) {
                            showDialog(
                              context: context,
                              builder: (context) => ErrorDialog(
                                message: "Username already exists",
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          return _glassButton(
                            label: "Sign Up",
                            isLoading: state is SignupLoading,
                            onPressed: () {
                              final body = RegisterRequestModel(
                                username: usernameController.text,
                                password: passwordController.text,
                                email: emailController.text,
                                name: usernameController.text,
                              );

                              context.read<RegisterBloc>().add(Signup(body));
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?  ",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                              );
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && isObscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: isPassword
              ? IconButton(
            onPressed: onToggle,
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.6),
            ),
          )
              : null,
        ),
      ),
    );
  }

  Widget _glassButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Center(
          child: isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
