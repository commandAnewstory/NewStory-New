# 서브플랜: getPopular() 실제 조회수 기반으로 수정

## 목표
`NewsService.getPopular()` 가 현재 `createdAt` desc 정렬(= 최신순)로 동작 중. `article_views` 테이블의 실제 조회 수 기반 정렬로 교체.

## 원인
`NewsService.getPopular()` (line 51-54):
```java
Sort sort = Sort.by("createdAt").descending();
return newsArticleRepository.findAll(sort)...
```
`ArticleViewRepository` 가 주입되어 있으나 `getPopular()` 에서 미사용.

## 변경 파일
- `backend/src/main/java/.../news/service/NewsService.java`
- `backend/src/main/java/.../news/repository/NewsArticleRepository.java` (쿼리 추가)

## 변경 내용
- `NewsArticleRepository` 에 JPQL/네이티브 쿼리 추가:
  ```java
  @Query("SELECT a FROM NewsArticle a LEFT JOIN ArticleView v ON v.article = a " +
         "GROUP BY a ORDER BY COUNT(v) DESC")
  List<NewsArticle> findTopByViewCount(Pageable pageable);
  ```
- `NewsService.getPopular()` 에서 위 쿼리 호출, top 20 반환
- 조회수 동점 시 `publishedAt` desc 2차 정렬

## 완료 기준
- `GET /api/news/popular` 응답이 실제 조회 많은 기사 순으로 정렬됨
- 조회수 0인 기사보다 조회수 있는 기사가 앞에 옴 (DB에서 확인)

## 영향 범위
- `NewsService.getPopular()` 변경
- `NewsArticleRepository` 쿼리 추가
- `GET /api/news/popular` 엔드포인트만 영향
