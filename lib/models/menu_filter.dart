class MenuFilter {
  final int menuId;
  final String menuName;
  final String category;
  final String categoryName;
  final String description;
  final List<MenuTag> tags;

  MenuFilter({
    required this.menuId,
    required this.menuName,
    required this.category,
    required this.categoryName,
    required this.description,
    required this.tags,
  });

  factory MenuFilter.fromJson(Map<String, dynamic> json) {
    return MenuFilter(
      menuId: json['menuId'],
      menuName: json['menuName'],
      category: json['category'],
      categoryName: json['categoryName'],
      description: json['description'],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => MenuTag.fromJson(tag))
              .toList() ??
          [],
    );
  }
}


class MenuTag {
  final String tagSeq;
  final String codeId;
  final String tagName;

  MenuTag({
    required this.tagSeq,
    required this.codeId,
    required this.tagName,
  });

  factory MenuTag.fromJson(Map<String, dynamic> json) {
    return MenuTag(
      tagSeq: json['tagSeq'].toString(),
      codeId: json['codeId'],
      tagName: json['tagName'],
    );
  }
}