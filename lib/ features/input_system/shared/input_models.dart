enum InputType { text, voice, camera, gallery }

class InputData {
  final InputType type;
  final String content;
  final String? title;
  final String rawInput;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? imageUrl;

  InputData({
    required this.type,
    required this.content,
    this.title,
    required this.rawInput,
    required this.timestamp,
    this.metadata,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'content': content,
      'title': title,
      'rawInput': rawInput,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'imageUrl': imageUrl,
    };
  }
}
