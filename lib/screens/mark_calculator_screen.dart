import 'package:flutter/material.dart';

class MarkCalculatorScreen extends StatefulWidget {
  const MarkCalculatorScreen({super.key});

  @override
  State<MarkCalculatorScreen> createState() => _MarkCalculatorScreenState();
}

class _MarkCalculatorScreenState extends State<MarkCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _subjectControllers = [];
  final List<TextEditingController> _markControllers = [];
  
  double? _percentage;
  String? _grade;

  @override
  void initState() {
    super.initState();
    // Initialize with 5 subjects
    for (int i = 0; i < 5; i++) {
      _subjectControllers.add(TextEditingController());
      _markControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _subjectControllers) {
      controller.dispose();
    }
    for (var controller in _markControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubject() {
    setState(() {
      _subjectControllers.add(TextEditingController());
      _markControllers.add(TextEditingController());
    });
  }

  void _removeSubject(int index) {
    if (_subjectControllers.length > 1) {
      setState(() {
        _subjectControllers[index].dispose();
        _markControllers[index].dispose();
        _subjectControllers.removeAt(index);
        _markControllers.removeAt(index);
      });
    }
  }

  void _calculateMarks() {
    if (!_formKey.currentState!.validate()) return;

    double totalMarks = 0;
    int subjectCount = 0;

    for (var controller in _markControllers) {
      if (controller.text.isNotEmpty) {
        totalMarks += double.parse(controller.text);
        subjectCount++;
      }
    }

    if (subjectCount > 0) {
      double percentage = totalMarks / subjectCount;
      setState(() {
        _percentage = percentage;
        _grade = _getGrade(percentage);
      });
    }
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'O (Outstanding)';
    if (percentage >= 80) return 'A+ (Excellent)';
    if (percentage >= 70) return 'A (Very Good)';
    if (percentage >= 60) return 'B+ (Good)';
    if (percentage >= 50) return 'B (Above Average)';
    if (percentage >= 40) return 'C (Average)';
    return 'F (Fail)';
  }

  void _reset() {
    setState(() {
      for (var controller in _subjectControllers) {
        controller.clear();
      }
      for (var controller in _markControllers) {
        controller.clear();
      }
      _percentage = null;
      _grade = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.06;
    
    return Scaffold(
      backgroundColor: const Color(0xFF252525),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252525),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mark Calculator',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your subject marks (out of 100)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(_subjectControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _subjectControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Subject ${index + 1}',
                            labelStyle: const TextStyle(color: Color(0xFF888888)),
                            filled: true,
                            fillColor: const Color(0xFFD9D9D9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _markControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Marks',
                            labelStyle: const TextStyle(color: Color(0xFF888888)),
                            filled: true,
                            fillColor: const Color(0xFFD9D9D9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final mark = double.tryParse(value);
                            if (mark == null) return 'Invalid';
                            if (mark < 0 || mark > 100) return '0-100';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_subjectControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeSubject(index),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add),
                label: const Text('Add Subject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculateMarks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F5AB1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Calculate',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              if (_percentage != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D3D),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Result',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_percentage!.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          color: Color(0xFF7F5AB1),
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _grade!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
