import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard


class SubjectSyllabusScreen extends StatelessWidget {
  final String subjectName;

  const SubjectSyllabusScreen({Key? key, required this.subjectName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    final List<Map<String, String>> syllabusUnits = [
      {
        'title': 'UNIT I (12 Hrs)',
        'content':
            'LINEAR ALGEBRA (MATRICES): Rank of a matrix - Consistency of a system of linear equations - '
            'Characteristic equation of a matrix - Eigen values and Eigen vectors - Properties of Eigen values and Eigen vectors - '
            'Cayley-Hamilton theorem (excluding proof) - Verification - Application (Finding Inverse and Power of a matrix) - '
            'Diagonalization of a matrix by orthogonal and similarity transformation - Quadratic form – Nature of Quadratic Form - '
            'Orthogonal reduction of quadratic form to canonical form.'
      },
      {
        'title': 'UNIT II (12 Hrs)',
        'content':
            'ORDINARY DIFFERENTIAL EQUATIONS: Differential Equations of First Order - Exact equations - Leibnitz’s linear equations - '
            'Bernoulli’s equation - Equations solvable for p - Clairaut’s equation - Differential equations of Higher order - '
            'Linear differential equations of higher order with constant coefficients - Euler’s linear equation of higher order '
            'with variable coefficients - Method of variation of parameters.'
      },
      {
        'title': 'UNIT III (12 Hrs)',
        'content':
            'MULTIVARIABLE CALCULUS (DIFFERENTIATION): Partial differentiation - Partial derivatives of first order and higher order - '
            'Partial differentiation of implicit functions - Euler’s theorem on homogeneous functions - Total derivative - Jacobian Properties - '
            'Taylor’s series for functions of two variables - Maxima and minima of functions of two variables.'
      },
      {
        'title': 'UNIT IV (12 Hrs)',
        'content':
            'MULTIVARIABLE CALCULUS (MULTIPLE INTEGRALS): Double integration (Cartesian form and Polar form) - constant limits - variable limits - '
            'over the region R - Change of variables in double integrals (Cartesian to polar) - Application of double integral - Area by double integration - '
            'Change of Order of Integration - Triple Integration (Cartesian, Spherical and Cylindrical) - constant limits - variable limits - over the region R - '
            'Application of triple integral - Volume by triple integration.'
      },
      {
        'title': 'UNIT V (12 Hrs)',
        'content':
            'MULTIVARIABLE CALCULUS (VECTOR CALCULUS): Vector Differential Operator - Gradient - Properties - Directional derivative - '
            'Divergence and Curl Properties and relations - Solenoidal and Irrotational vector fields - Line integral and Surface integrals - '
            'Integral Theorems (excluding Proof) - Green’s theorem - Stoke’s theorem - Gauss divergence theorem.'
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          // Top curved banner with back button
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Subject Syllabus',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable syllabus units
          Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: syllabusUnits.length,
            itemBuilder: (context, index) {
              final unit = syllabusUnits[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          unit['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: 'Copy syllabus',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: unit['content']!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Syllabus copied to clipboard!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        unit['content']!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
        ],
      ),
    );
  }
}
