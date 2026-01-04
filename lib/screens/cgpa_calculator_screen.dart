import 'package:flutter/material.dart';

class CgpaCalculatorScreen extends StatefulWidget {
  const CgpaCalculatorScreen({super.key});

  @override
  State<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends State<CgpaCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<SemesterData> _semesters = [];
  
  double? _cgpa;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 semesters
    _addSemester();
    _addSemester();
  }

  void _addSemester() {
    setState(() {
      _semesters.add(SemesterData(
        semesterNumber: _semesters.length + 1,
        gpaController: TextEditingController(),
        creditsController: TextEditingController(),
      ));
    });
  }

  void _removeSemester(int index) {
    if (_semesters.length > 1) {
      setState(() {
        _semesters[index].dispose();
        _semesters.removeAt(index);
        // Update semester numbers
        for (int i = 0; i < _semesters.length; i++) {
          _semesters[i].semesterNumber = i + 1;
        }
      });
    }
  }

  void _calculateCGPA() {
    if (!_formKey.currentState!.validate()) return;

    double totalGradePoints = 0;
    double totalCredits = 0;

    for (var semester in _semesters) {
      if (semester.gpaController.text.isNotEmpty &&
          semester.creditsController.text.isNotEmpty) {
        double gpa = double.parse(semester.gpaController.text);
        double credits = double.parse(semester.creditsController.text);
        totalGradePoints += gpa * credits;
        totalCredits += credits;
      }
    }

    if (totalCredits > 0) {
      setState(() {
        _cgpa = totalGradePoints / totalCredits;
      });
    }
  }

  void _reset() {
    setState(() {
      for (var semester in _semesters) {
        semester.gpaController.clear();
        semester.creditsController.clear();
      }
      _cgpa = null;
    });
  }

  String _getGradeClassification(double cgpa) {
    if (cgpa >= 9.0) return 'Outstanding';
    if (cgpa >= 8.0) return 'Excellent';
    if (cgpa >= 7.0) return 'Very Good';
    if (cgpa >= 6.0) return 'Good';
    if (cgpa >= 5.0) return 'Average';
    return 'Pass';
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
          'CGPA Calculator',
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
                'Enter GPA and Credits for each semester',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(_semesters.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3D3D),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Semester ${_semesters[index].semesterNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_semesters.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeSemester(index),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _semesters[index].gpaController,
                                decoration: InputDecoration(
                                  labelText: 'GPA (0-10)',
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
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final gpa = double.tryParse(value);
                                  if (gpa == null) return 'Invalid';
                                  if (gpa < 0 || gpa > 10) return '0-10';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _semesters[index].creditsController,
                                decoration: InputDecoration(
                                  labelText: 'Credits',
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
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final credits = double.tryParse(value);
                                  if (credits == null) return 'Invalid';
                                  if (credits <= 0) return '> 0';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addSemester,
                icon: const Icon(Icons.add),
                label: const Text('Add Semester'),
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
                      onPressed: _calculateCGPA,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB55B61),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Calculate CGPA',
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
              if (_cgpa != null) ...[
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
                        'Your CGPA',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _cgpa!.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Color(0xFFB55B61),
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getGradeClassification(_cgpa!),
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

class SemesterData {
  int semesterNumber;
  final TextEditingController gpaController;
  final TextEditingController creditsController;

  SemesterData({
    required this.semesterNumber,
    required this.gpaController,
    required this.creditsController,
  });

  void dispose() {
    gpaController.dispose();
    creditsController.dispose();
  }
}
