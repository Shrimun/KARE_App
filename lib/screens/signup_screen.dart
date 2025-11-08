import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_dialog.dart';
import '../models/department.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  // Department dropdown state
  String? _selectedDepartmentCode;
  List<Department> _departments = [];
  bool _loadingDepartments = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDepartments = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final departments = await auth.api.getDepartments();
      setState(() {
        _departments = departments;
        // Preselect first department if available
        if (_departments.isNotEmpty) {
          _selectedDepartmentCode = _departments.first.code;
        }
        _loadingDepartments = false;
      });
    } catch (e) {
      setState(() => _loadingDepartments = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => ErrorDialog(
            message: 'Failed to load departments: ${e.toString()}',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().length < 3)
      return 'Name must be at least 3 chars';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || !v.contains('@') || !v.endsWith('@klu.ac.in'))
      return 'Please use your @klu.ac.in email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 8) return 'Password must be at least 8 chars';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v))
      return 'Include letters and numbers';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty)
      return 'Phone number is required';
    // Accept phone with optional + prefix
    final cleaned = v.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned))
      return 'Enter valid phone (10-15 digits, optional +)';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.signup(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        department: _selectedDepartmentCode!,
        phoneNumber: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      showDialog(
          context: context, builder: (_) => ErrorDialog(message: e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: auth.isLoading
          ? const Center(child: LoadingWidget())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: _validateName),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _passwordCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: _validatePassword),
                    const SizedBox(height: 12),
                    _loadingDepartments
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedDepartmentCode,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(),
                            ),
                            items: _departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept.code,
                                child: Text('${dept.code} - ${dept.name}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDepartmentCode = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a department';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Phone Number (with country code)'),
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Create account')),
                    TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed('/login'),
                        child: const Text('Already have an account? Login'))
                  ],
                ),
              ),
            ),
    );
  }
}
