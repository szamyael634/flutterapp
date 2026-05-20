import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/models/app_user.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  AppRole _role = AppRole.buyer;
  bool _awaitingVerification = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final requiresVerification = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          role: _role,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );

    final state = ref.read(authControllerProvider);
    if (!mounted) {
      return;
    }

    if (state.hasError) {
      context.showSnackBar(state.error.toString(), isError: true);
      return;
    }

    if (requiresVerification) {
      setState(() => _awaitingVerification = true);
      context.showSnackBar(
        'Account created. Enter the verification code sent to your email.',
      );
      return;
    }

    context.showSnackBar('Account created successfully.');
    Navigator.of(context).pop();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .verifySignUpCode(
          email: _emailController.text.trim(),
          code: _verificationCodeController.text.trim(),
        );

    final state = ref.read(authControllerProvider);
    if (!mounted) {
      return;
    }

    if (state.hasError) {
      context.showSnackBar(state.error.toString(), isError: true);
      return;
    }

    context.showSnackBar('Email verified. You can now use your account.');
    Navigator.of(context).pop();
  }

  Future<void> _resendCode() async {
    await ref
        .read(authControllerProvider.notifier)
        .resendSignUpCode(email: _emailController.text.trim());

    final state = ref.read(authControllerProvider);
    if (!mounted) {
      return;
    }

    if (state.hasError) {
      context.showSnackBar(state.error.toString(), isError: true);
      return;
    }

    context.showSnackBar('A new verification code was sent to your email.');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: !_awaitingVerification,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        validator: (value) =>
                            value != null && value.trim().isNotEmpty
                            ? null
                            : 'Enter your name',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AppRole>(
                        initialValue: _role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: AppRole.values
                            .where((role) => role != AppRole.admin)
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.name),
                              ),
                            )
                            .toList(),
                        onChanged: _awaitingVerification
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _role = value);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_awaitingVerification,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            value != null && value.contains('@')
                            ? null
                            : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_awaitingVerification,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_awaitingVerification,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : 'Password must be at least 6 characters',
                      ),
                      if (_awaitingVerification) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _verificationCodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Verification code',
                            helperText: 'Enter the code sent to your email.',
                          ),
                          validator: (value) {
                            if (!_awaitingVerification) {
                              return null;
                            }

                            return value != null && value.trim().length >= 6
                                ? null
                                : 'Enter the verification code';
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: authState.isLoading
                            ? null
                            : _awaitingVerification
                            ? _verifyCode
                            : _submit,
                        child: authState.isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _awaitingVerification
                                    ? 'Verify code'
                                    : 'Create account',
                              ),
                      ),
                      if (_awaitingVerification) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: authState.isLoading ? null : _resendCode,
                          child: const Text('Resend verification code'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
