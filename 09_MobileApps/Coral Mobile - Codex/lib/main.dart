import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'src/app.dart';
import 'src/core/database_helper.dart';
import 'src/features/assessment/data/offline_prediction_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      // Ignore if device does not support high refresh rate
    }
  }

  // Allow Google Fonts to fetch at runtime since fonts aren't bundled.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Warm up slow startup work without blocking the first frame.
  unawaited(DatabaseHelper.instance.database);
  unawaited(OfflinePredictionService().preload());

  runApp(const CoralHealthApp());
}

// Trigger hot reload/restart.
