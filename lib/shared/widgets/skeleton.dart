import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget skeletonItem() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      height: 150,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
