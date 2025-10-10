import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';
import 'forget_password_page.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _phoneNumber = TextEditingController();
  String _role = 'tenant';

  bool _isSignIn = true;
  bool _obscure = true;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  String? _fullNameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _email.text.trim();
    final pwd = _password.text;
    final name = _fullName.text.trim();
    final phone = _phoneNumber.text.trim();
    final role = _role;

    final ctrl = ref.read(authControllerProvider.notifier);

    if (_isSignIn) {
      await ctrl.signIn(email, pwd);
    } else {
      await ctrl.signUp(
        email: email,
        password: pwd,
        fullName: name,
        phoneNumber: phone,
        role: role,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFF1C9826),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C9826),
          primary: const Color(0xFF1C9826),
          secondary: const Color(0xFF4CAF50),
          surface: Colors.white,
          error: Colors.redAccent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C9826),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1C9826),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 380 : 420),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.apartment,
                      size: 64,
                      color: Color(0xFF1C9826),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSignIn ? 'Welcome Back' : 'Create Your Account',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignIn
                          ? 'Sign in to continue'
                          : 'Join us to book or manage rooms',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!_isSignIn) ...[
                                TextFormField(
                                  controller: _fullName,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: _fullNameValidator,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneNumber,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: _emailValidator,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                validator: _passwordValidator,
                                autofillHints: const [AutofillHints.password],
                              ),
                              if (_isSignIn) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgetPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: const Text('Forgot Password?'),
                                  ),
                                ),
                              ],
                              if (!_isSignIn) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Choose your role:',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tenant: Book and manage rooms.\n'
                                  'Owner: Manage your guest house and list rooms.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Tenant'),
                                        value: 'tenant',
                                        groupValue: _role,
                                        onChanged: (v) =>
                                            setState(() => _role = v!),
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: const Color(0xFF1C9826),
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Owner'),
                                        value: 'guest_house_owner',
                                        groupValue: _role,
                                        onChanged: (v) =>
                                            setState(() => _role = v!),
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: const Color(0xFF1C9826),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: status is AuthLoading
                                      ? null
                                      : _submit,
                                  child: Text(
                                    _isSignIn ? 'Sign In' : 'Sign Up',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: status is AuthLoading
                                      ? null
                                      : () => setState(
                                          () => _isSignIn = !_isSignIn,
                                        ),
                                  child: Text(
                                    _isSignIn
                                        ? 'No account? Create one'
                                        : 'Have an account? Sign in',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (status is AuthLoading)
                      const CircularProgressIndicator(),
                    if (status is AuthError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          status.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
