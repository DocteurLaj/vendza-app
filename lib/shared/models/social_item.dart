import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialItem {
  final FaIconData icon;
  final Color? color;
  final Gradient? gradient;
  final String? url;

  const SocialItem({required this.icon, this.color, this.gradient, this.url});
}
