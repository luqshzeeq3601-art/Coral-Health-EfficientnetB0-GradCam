import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    final bytes = await File('assets/models/coral_base.tflite').readAsBytes();
    final interpreter = Interpreter.fromBuffer(bytes);
    print('Interpreter loaded from buffer! Inputs: ${interpreter.getInputTensors().length}');
    interpreter.close();
  } catch (e) {
    print('Error: $e');
  }
}
