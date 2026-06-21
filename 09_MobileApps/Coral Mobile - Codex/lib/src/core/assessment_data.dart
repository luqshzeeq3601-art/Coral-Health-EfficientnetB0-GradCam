class AssessmentData {
  const AssessmentData({
    required this.fileName,
    required this.fileSize,
    required this.confidence,
  });

  final String fileName;
  final String fileSize;
  final String confidence;
}

const sampleAssessment = AssessmentData(
  fileName: 'coral_sample_01.jpg',
  fileSize: '4.2 MB',
  confidence: '97.4%',
);
