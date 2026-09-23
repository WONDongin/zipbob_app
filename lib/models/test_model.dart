class TestModel{
  final String col1;
  final String col2;
  final String col3;

  TestModel({required this.col1, required this.col2, required this.col3});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      col1: json['col1'] ?? '',
      col2: json['col2'] ?? '',
      col3: json['col3'] ?? '',
    );
  }
}