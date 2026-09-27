# 집밥PICK (zipbob_app)

> 고민은 짧게, 집밥은 맛있게

집밥PICK은 오늘 먹을 메뉴를 고르고 레시피를 살펴보는 Flutter 앱 프로젝트입니다. 현재는 주요 화면과 이동 흐름을 구현한 초기 단계이며, 추천 결과에는 예시 데이터를 사용합니다.

## 프로젝트 개요

- **목적:** 메뉴 선택부터 레시피 확인까지 이어지는 모바일 경험 제공
- **기술:** Dart, Flutter, Material 3, `http`
- **협업 백엔드:** [zipbob_back](https://github.com/hyeseon1020/zipbob_back) (Spring Boot)

## 현재 구현된 화면

| 화면      | 현재 동작                                            |
| --------- | ---------------------------------------------------- |
| 홈        | 전체 메뉴, 즐겨찾기, 조건 선택 화면으로 이동         |
| 전체 메뉴 | 예시 메뉴 카드와 레시피 화면 이동                    |
| 조건 선택 | 카테고리 단일 선택, 음식 특징 다중 선택, 선택 초기화 |
| 추천 결과 | 예시 메뉴 순환, 레시피 보기, 조건 변경               |
| 레시피    | 메뉴명 및 전달된 재료·조리 순서 등을 표시하는 화면   |
| 즐겨찾기  | 빈 목록 안내와 전체 메뉴 이동                        |

> 검색, 실제 조건에 따른 메뉴 필터링, 레시피 데이터 연결, 즐겨찾기 저장, 홈의 랜덤 추천은 개발 중입니다. 조건 화면의 추천 가능 개수와 추천 결과 메뉴는 현재 예시 값입니다.

## 화면 흐름

```text
홈
├─ 전체 메뉴 → 메뉴 선택 → 레시피
├─ 조건 골라 추천 → 조건 선택 → 추천 결과 → 레시피
└─ 즐겨찾기 → 전체 메뉴
```

## 프로젝트 구조

```text
lib/
├─ main.dart                 # 앱 진입점과 테마
├─ screens/                  # 홈, 메뉴, 조건 선택, 추천 결과, 레시피, 즐겨찾기
├─ services/api_service.dart # Spring Boot 연결 확인용 API 요청
└─ models/test_model.dart    # 테스트 API 응답 모델
test/
├─ widget_test.dart          # 홈에서 즐겨찾기로 이동하는 테스트
└─ api_connection_test.dart  # 로컬 Spring Boot 서버 연동 테스트
```

## 실행 방법

Flutter SDK와 Android 에뮬레이터 또는 기기를 준비합니다.

```bash
git clone https://github.com/WONDongin/zipbob_app.git
cd zipbob_app
flutter pub get
flutter run
```

앱의 화면 이동은 백엔드 없이 확인할 수 있습니다. `ApiService`는 현재 화면에 연결된 레시피 API가 아니라 별도의 연결 확인용 테스트 API입니다.

### 로컬 API 연결 테스트

`test/api_connection_test.dart`는 `GET /api/test`를 제공하는 로컬 Spring Boot 서버가 실행 중이어야 통과합니다. 현재 `ApiService.baseUrl`은 Android 에뮬레이터 기준 `http://10.0.2.2:8080/api/test`입니다. Chrome 또는 호스트 PC에서 테스트할 때는 `lib/services/api_service.dart`의 주소를 `http://localhost:8080/api/test`로 변경합니다.

```bash
flutter test test/widget_test.dart
flutter test test/api_connection_test.dart
```

## 다음 작업

- 실제 메뉴·레시피 데이터와 화면 연결
- 선택 조건에 따른 추천 로직 구현
- 메뉴 검색 및 즐겨찾기 저장 기능 구현

## 관련 저장소

- [Flutter 앱: zipbob_app](https://github.com/WONDongin/zipbob_app)
- [Spring Boot 백엔드: zipbob_back](https://github.com/hyeseon1020/zipbob_back)
