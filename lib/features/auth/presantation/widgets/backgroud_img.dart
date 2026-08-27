import 'package:flutter/material.dart';

class BackgroudImg extends StatelessWidget {
  const BackgroudImg({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/login_img.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.66),
                Colors.black.withValues(alpha: 0.54),
                Colors.black.withValues(alpha: 0.74),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
