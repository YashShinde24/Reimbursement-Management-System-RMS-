import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/currency_service.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  // Login fields
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Signup fields
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  CountryInfo? _selectedCountry;
  List<CountryInfo> _countries = [];
  bool _loadingCountries = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries = await CurrencyService().getCountries();
    if (mounted) {
      setState(() {
        _countries = countries;
        _loadingCountries = false;
        try {
          _selectedCountry = countries.firstWhere(
              (c) => c.name.toLowerCase() == 'india');
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F0F23),
                    const Color(0xFF1A1A3E),
                    const Color(0xFF2D1B69),
                  ]
                : [
                    const Color(0xFFEEEBFF),
                    const Color(0xFFF5F7FA),
                    const Color(0xFFE8F4FD),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildForm(),
                      const SizedBox(height: 16),
                      _buildToggle(),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.accentColor],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'ExpenseFlow',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Create your company account'
              : 'Sign in to continue',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_isSignUp) ...[
              _buildTextField(
                controller: _nameCtrl,
                label: 'Your Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _companyCtrl,
                label: 'Company Name',
                icon: Icons.business_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _buildCountrySelector(),
              const SizedBox(height: 14),
            ],
            _buildTextField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _passwordCtrl,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 4) return 'Min 4 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (ctx, auth, _) {
                if (auth.error != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(
                          color: AppTheme.errorColor, fontSize: 13),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Consumer<AuthProvider>(
                builder: (ctx, auth, _) {
                  return ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildCountrySelector() {
    if (_loadingCountries) {
      return const LinearProgressIndicator();
    }

    return DropdownButtonFormField<CountryInfo>(
      value: _selectedCountry,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(Icons.public, size: 20),
      ),
      items: _countries.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(
            '${c.name} (${c.currencyCode})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedCountry = v),
      validator: (v) => v == null ? 'Select a country' : null,
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp
              ? 'Already have an account?'
              : "Don't have an account?",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            setState(() => _isSignUp = !_isSignUp);
            context.read<AuthProvider>().clearError();
          },
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    if (_isSignUp) {
      if (_selectedCountry == null) return;
      await auth.signUp(
        companyName: _companyCtrl.text.trim(),
        adminName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        country: _selectedCountry!.name,
        currencyCode: _selectedCountry!.currencyCode,
        currencyName: _selectedCountry!.currencyName,
        currencySymbol: _selectedCountry!.currencySymbol,
      );
    } else {
      await auth.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
    }
  }
}
