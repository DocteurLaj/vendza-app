import 'package:flutter/material.dart';
import 'package:vendza/features/auth/presantation/widgets/header.dart';

class AuthHeaderSpace extends StatelessWidget {
  const AuthHeaderSpace({
    super.key,
    required this.heightFactor,
    this.topPadding = 26,
  });

  final double heightFactor;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final isShortScreen = MediaQuery.sizeOf(context).height < 700;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * heightFactor,
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                top: isShortScreen ? topPadding * 0.6 : topPadding,
              ),
              child: const HeaderWidget(),
            ),
          ),
        ),
      ),
    );
  }
}
