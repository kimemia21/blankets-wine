import 'dart:ui';

import 'package:flutter/material.dart';

Widget servigram() {
  return Text(
    '🚀 Powered by Servigram',
    style: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      shadows: [
        Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(1, 1)),
      ],
    ),
    textAlign: TextAlign.center,
  );
}
