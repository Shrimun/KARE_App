import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

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
          'Rules and Regulations',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleSection(
              'Academic Regulations',
              [
                'Students must maintain a minimum of 75% attendance in all subjects.',
                'Late submissions of assignments will result in grade penalties.',
                'Plagiarism in any form is strictly prohibited and will lead to disciplinary action.',
                'Students must adhere to the examination code of conduct.',
              ],
            ),
            const SizedBox(height: 24),
            _buildRuleSection(
              'Dress Code',
              [
                'Students must wear their ID cards at all times on campus.',
                'Formal dress code is mandatory during college hours.',
                'Casual wear is not permitted in classrooms and labs.',
              ],
            ),
            const SizedBox(height: 24),
            _buildRuleSection(
              'Library Rules',
              [
                'Silence must be maintained in the library premises.',
                'Books borrowed must be returned within the due date.',
                'Late return of books will incur a fine.',
                'No food or drinks allowed in the library.',
              ],
            ),
            const SizedBox(height: 24),
            _buildRuleSection(
              'Hostel Regulations',
              [
                'Hostel curfew timings must be strictly followed.',
                'Visitors are allowed only during specified hours.',
                'Room inspections will be conducted periodically.',
                'Ragging in any form is a punishable offense.',
              ],
            ),
            const SizedBox(height: 24),
            _buildRuleSection(
              'Disciplinary Code',
              [
                'Use of mobile phones is restricted in classrooms.',
                'Respect towards faculty and staff is mandatory.',
                'Any form of misbehavior will lead to disciplinary action.',
                'Damage to college property will result in financial penalties.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleSection(String title, List<String> rules) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF3F967F),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
