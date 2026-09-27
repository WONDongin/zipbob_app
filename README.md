# 집밥PICK (zipbob_app)

> 고민은 짧게, 집밥은 맛있게

집밥PICK은 오늘 먹을 메뉴를 고르고 레시피를 살펴보는 Flutter 앱 프로젝트입니다. 현재는 주요 화면과 이동 흐름을 구현한 초기 단계이며, 메뉴와 추천 결과에는 예시 데이터를 사용합니다.

## 프로젝트 개요

- **목적:** 메뉴 선택부터 레시피 확인까지 이어지는 모바일 경험 제공
- **기술:** Dart, Flutter, Material 3, `http`
- **협업 백엔드:** [zipbob_back](https://github.com/hyeseon1020/zipbob_back) (Spring Boot)

## 완료한 작업

- `main.dart`에서 앱 이름을 **집밥PICK**으로 변경
- `home_screen.dart`에서 **조건 골라 추천** 버튼을 조건 선택 화면에 연결
- `filter_screen.dart`에 카테고리와 음식 특징 선택 화면 구성
  - **이 조건으로 추천하기**를 누르면 추천 결과 화면으로 이동
  - **선택 초기화**를 누르면 카테고리를 `전체`로 변경하고 선택한 특징을 해제
- `recommend_result_screen.dart`에 추천 결과 화면 구성
  - **레시피 보기**를 누르면 레시피 화면으로 이동
  - **다시 추천**을 누르면 예시 메뉴를 순서대로 변경
  - **조건 변경**을 누르면 조건 선택 화면으로 이동

## 현재 구현된 화면

| 화면      | 현재 동작                                            |
| --------- | ---------------------------------------------------- |
| 홈        | 전체 메뉴, 즐겨찾기, 조건 선택 화면으로 이동         |
| 전체 메뉴 | 예시 메뉴 카드 표시 및 레시피 화면 이동              |
| 조건 선택 | 카테고리 단일 선택, 음식 특징 다중 선택, 선택 초기화 |
| 추천 결과 | 예시 메뉴 순환, 레시피 보기, 조건 변경               |
| 레시피    | 메뉴명과 전달받은 재료·조리 순서 등을 표시           |
| 즐겨찾기  | 빈 목록 안내 및 전체 메뉴 이동                       |

## 현재 화면 흐름

```text
홈 → 돋보기 → 전체 메뉴 → 음식 카드 → 레시피 상세
홈 → 하트 → 즐겨찾기 → 전체 메뉴
홈 → 조건 골라 추천 → 이 조건으로 추천하기 → 오늘의 추천 → 레시피 보기 → 레시피 상세
```

홈의 **아무거나 추천** 버튼은 현재 임시 화면으로 이동합니다.

> 검색, 실제 조건에 따른 메뉴 필터링, 레시피 데이터 연결, 즐겨찾기 저장, 랜덤 추천은 아직 구현되지 않았습니다. 추천 가능 개수와 추천 결과 메뉴는 현재 예시 값입니다.

## 프로젝트 구조

```text
lib/
├─ main.dart                  # 앱 진입점과 테마
├─ screens/                  # 홈, 메뉴, 조건 선택, 추천 결과, 레시피, 즐겨찾기
├─ services/api_service.dart # Spring Boot 연결 확인용 API 요청
└─ models/test_model.dart    # 테스트 API 응답 모델
test/
├─ widget_test.dart          # 화면 이동 테스트
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

화면 이동은 백엔드 없이 확인할 수 있습니다. 현재 `ApiService`는 레시피 화면에 연결된 API가 아니라 별도의 연결 확인용 테스트 API입니다.

### 로컬 API 연결 테스트

`test/api_connection_test.dart`는 `GET /api/test`를 제공하는 로컬 Spring Boot 서버가 실행 중이어야 통과합니다. `ApiService.baseUrl`은 실행 환경에 맞게 설정해야 합니다.

- Android 에뮬레이터에서 PC의 서버에 접근: `http://10.0.2.2:8080/api/test`
- Chrome 또는 호스트 PC에서 접근: `http://localhost:8080/api/test`

```bash
flutter test test/widget_test.dart
flutter test test/api_connection_test.dart
```

## 다음 작업

- 백엔드 API와 실제 메뉴·레시피 데이터 연결
- 메뉴명 검색 및 카테고리별 목록 조회
- 선택 조건에 따른 추천 및 랜덤 추천 구현
- 로그인 이후 즐겨찾기 저장·조회 기능 구현
- 코드 관리 및 메뉴 관리 기능의 인증 방식과 접근 경로 결정

## 관련 저장소

- [Flutter 앱: zipbob_app](https://github.com/WONDongin/zipbob_app)
- [Spring Boot 백엔드: zipbob_back](https://github.com/hyeseon1020/zipbob_back)
