// 전체 메뉴 목록 API의 메뉴 한 개를 표현하는 모델
class AllMenuScreenModel {
  const AllMenuScreenModel({
    required this.menuId,
    required this.menuName,
    this.category,
    this.categoryName,
    this.description,
    this.imageUrl,
  });

  final int menuId;
  final String menuName;
  final String? category; // 검색에 사용하는 코드값
  final String? categoryName; // 화면에 표시하는 한글 이름
  final String? description;
  final String? imageUrl;

  // JSON 데이터를 Dart 객체로 변환
  factory AllMenuScreenModel.fromJson(Map<String, dynamic> json) {
    return AllMenuScreenModel(
      menuId: (json['menuId'] as num).toInt(),
      menuName: json['menuName'] as String,
      category: json['category'] as String?,
      categoryName: json['categoryName'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/*
| 문법 | 의미 |
| `required` | 객체를 만들 때 반드시 전달할 값 |
| `String?` | 문자열 또는 `null` 허용 |
| `final` | 값을 설정한 뒤 재할당 불가 |
| `factory ...fromJson` | JSON을 받아 모델 객체를 만드는 생성자 |
| `(… as num).toInt()` | JSON 숫자를 Dart 정수로 변환 |
*/
