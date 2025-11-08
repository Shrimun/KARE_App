import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_dialog.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  bool _loading = false;
  String? _answer;

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = Provider.of<AuthProvider>(context, listen: false).api;
    try {
      final res = await api.askQuestion(question: _questionCtrl.text.trim());
      setState(() {
        _answer =
            res['answer']?.toString() ?? res['data']?.toString() ?? 'No answer';
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: e.toString()),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask a question')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _questionCtrl,
                decoration: const InputDecoration(labelText: 'Your question'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a question' : null,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 12),
            _loading
                ? const LoadingWidget()
                : ElevatedButton(onPressed: _submit, child: const Text('Ask')),
            const SizedBox(height: 16),
            if (_answer != null)
              Expanded(child: SingleChildScrollView(child: Text(_answer!))),
          ],
        ),
      ),
    );
  }
}
