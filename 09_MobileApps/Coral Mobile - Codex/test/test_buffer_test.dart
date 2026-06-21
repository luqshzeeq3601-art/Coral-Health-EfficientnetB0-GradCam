import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  test('Inspect TFLite model', () {
    try {
      final bytes = File('assets/models/coral_base.tflite').readAsBytesSync();
      final interpreter = Interpreter.fromBuffer(bytes);
      
      print('Inputs:');
      for (var tensor in interpreter.getInputTensors()) {
        print('- ${tensor.name}: shape=${tensor.shape}, type=${tensor.type}');
      }

      print('Outputs:');
      for (var tensor in interpreter.getOutputTensors()) {
        print('- ${tensor.name}: shape=${tensor.shape}, type=${tensor.type}');
      }
      
      interpreter.close();
    } catch (e) {
      print('Error: $e');
    }
  });
}
