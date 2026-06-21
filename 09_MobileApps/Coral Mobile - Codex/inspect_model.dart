import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    final interpreter = Interpreter.fromFile(File('assets/models/coral_base.tflite'));
    final inputTensors = interpreter.getInputTensors();
    final outputTensors = interpreter.getOutputTensors();

    print('Inputs:');
    for (var tensor in inputTensors) {
      print('- ${tensor.name}: shape=${tensor.shape}, type=${tensor.type}');
    }

    print('Outputs:');
    for (var tensor in outputTensors) {
      print('- ${tensor.name}: shape=${tensor.shape}, type=${tensor.type}');
    }
    
    interpreter.close();
  } catch (e) {
    print('Error: $e');
  }
}
