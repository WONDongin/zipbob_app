class Code {
  final String codeId;
  final String codeName;

  Code({
    required this.codeId,
    required this.codeName,
  });

  factory Code.fromJson(Map<String, dynamic> json) {
    return Code(
      codeId: json['codeId'],
      codeName: json['codeName'],
    );
  }
}