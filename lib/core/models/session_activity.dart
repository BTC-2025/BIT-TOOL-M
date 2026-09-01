class SessionActivity {
  final String id;
  final String iconName;
  final DateTime timestamp;
  final String device;
  final String module;
  final String duration;
  final String status;
  final String description;
  final String category;

  SessionActivity({
    required this.id,
    required this.iconName,
    required this.timestamp,
    required this.device,
    required this.module,
    required this.duration,
    required this.status,
    required this.description,
    required this.category,
  });

  factory SessionActivity.fromJson(Map<String, dynamic> json) {
    return SessionActivity(
      id: json['id'] as String,
      iconName: json['iconName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      device: json['device'] as String,
      module: json['module'] as String,
      duration: json['duration'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iconName': iconName,
      'timestamp': timestamp.toIso8601String(),
      'device': device,
      'module': module,
      'duration': duration,
      'status': status,
      'description': description,
      'category': category,
    };
  }
}
