import 'package:flutter/material.dart';

class CreditsCalculatorScreen extends StatefulWidget {
  const CreditsCalculatorScreen({super.key});

  @override
  State<CreditsCalculatorScreen> createState() => _CreditsCalculatorScreenState();
}

class _CreditsCalculatorScreenState extends State<CreditsCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<CourseData> _courses = [];
  
  int? _totalCredits;
  int? _remainingCredits;
  final int _requiredCredits = 160; // Total credits required for graduation

  @override
  void initState() {
    super.initState();
    // Initialize with 3 courses
    for (int i = 0; i < 3; i++) {
      _addCourse();
    }
  }

  void _addCourse() {
    setState(() {
      _courses.add(CourseData(
        courseNameController: TextEditingController(),
        creditsController: TextEditingController(),
      ));
    });
  }

  void _removeCourse(int index) {
    if (_courses.length > 1) {
      setState(() {
        _courses[index].dispose();
        _courses.removeAt(index);
      });
    }
  }

  void _calculateCredits() {
    if (!_formKey.currentState!.validate()) return;

    int total = 0;

    for (var course in _courses) {
      if (course.creditsController.text.isNotEmpty) {
        total += int.parse(course.creditsController.text);
      }
    }

    setState(() {
      _totalCredits = total;
      _remainingCredits = _requiredCredits - total;
    });
  }

  void _reset() {
    setState(() {
      for (var course in _courses) {
        course.courseNameController.clear();
        course.creditsController.clear();
      }
      _totalCredits = null;
      _remainingCredits = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.06;
    
    return Scaffold(
      backgroundColor: const Color(0xFFfdf0d5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfdf0d5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Credits Calculator',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Credits Required:',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$_requiredCredits',
                      style: const TextStyle(
                        color: Color(0xFF003049),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter your completed courses',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_courses.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Course ${index + 1}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_courses.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeCourse(index),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _courses[index].courseNameController,
                          decoration: InputDecoration(
                            labelText: 'Course Name',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _courses[index].creditsController,
                          decoration: InputDecoration(
                            labelText: 'Credits',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Credits required';
                            }
                            final credits = int.tryParse(value);
                            if (credits == null) return 'Invalid number';
                            if (credits <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addCourse,
                icon: const Icon(Icons.add),
                label: const Text('Add Course'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black26),
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
                      onPressed: _calculateCredits,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFc1121f),
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
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black26),
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
              if (_totalCredits != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Credits Completed:',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$_totalCredits',
                            style: const TextStyle(
                              color: Color(0xFF003049),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Credits Remaining:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$_remainingCredits',
                            style: TextStyle(
                              color: _remainingCredits! > 0
                                  ? const Color(0xFF669bbc)
                                  : Colors.green, // Completed
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _totalCredits! / _requiredCredits,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF669bbc),
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((_totalCredits! / _requiredCredits) * 100).toStringAsFixed(1)}% Complete',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (_remainingCredits! <= 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.celebration, color: Colors.green),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Congratulations! You have completed all required credits!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class CourseData {
  final TextEditingController courseNameController;
  final TextEditingController creditsController;

  CourseData({
    required this.courseNameController,
    required this.creditsController,
  });

  void dispose() {
    courseNameController.dispose();
    creditsController.dispose();
  }
}
