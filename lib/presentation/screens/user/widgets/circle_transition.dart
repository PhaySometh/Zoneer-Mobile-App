import 'package:flutter/material.dart';

Widget circle(Size size, Color color) {
  return Container(
    width: size.width,
    height: size.width,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
    ),
  );
}