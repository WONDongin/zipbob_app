// 카테고리, 음식특징 값 받아오기
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