package com.newstory.newstorybackend.domain.news.repository;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface NewsArticleRepository extends JpaRepository<NewsArticle, Long> {

  Optional<NewsArticle> findByUrl(String url);

  boolean existsByUrl(String url);

  Page<NewsArticle> findByCategory(String category, Pageable pageable);

  /** 제목 부분 일치 검색. [pattern]은 이미 소문자 + 이스케이프 + 앞뒤 % 처리된 값이어야 한다. */
  @Query(
      "SELECT a FROM NewsArticle a WHERE LOWER(a.title) LIKE :pattern ESCAPE '\\' "
          + "AND (:category IS NULL OR a.category = :category)")
  Page<NewsArticle> searchByTitle(String pattern, String category, Pageable pageable);

  @Query(
      "SELECT DISTINCT a.category FROM NewsArticle a WHERE a.category IS NOT NULL ORDER BY a.category")
  List<String> findDistinctCategories();

  @Query(
      "SELECT a FROM NewsArticle a LEFT JOIN ArticleView v ON v.article = a "
          + "GROUP BY a ORDER BY COUNT(v) DESC, a.publishedAt DESC NULLS LAST")
  List<NewsArticle> findTopByViewCount(Pageable pageable);

  /**
   * [since] 이후 올라온 기사를 [since] 이후 조회수 많은 순으로. 동률이면 최신순. [allCategories]가 true면 카테고리 무시 (JPQL은 빈 IN
   * 목록을 못 받아서 플래그로 구분).
   */
  @Query(
      "SELECT a FROM NewsArticle a LEFT JOIN ArticleView v ON v.article = a AND v.viewedAt >= :since "
          + "WHERE a.publishedAt >= :since AND (:allCategories = true OR a.category IN :categories) "
          + "GROUP BY a ORDER BY COUNT(v) DESC, a.publishedAt DESC")
  List<NewsArticle> findPopularSince(
      LocalDateTime since,
      boolean allCategories,
      java.util.Collection<String> categories,
      Pageable pageable);

  @Query(
      "SELECT a FROM NewsArticle a WHERE (:allCategories = true OR a.category IN :categories) "
          + "ORDER BY a.publishedAt DESC NULLS LAST")
  List<NewsArticle> findLatestIn(
      boolean allCategories, java.util.Collection<String> categories, Pageable pageable);

  @Query(
      "SELECT a.id FROM NewsArticle a WHERE a.publishedAt < :cutoff "
          + "AND NOT EXISTS (SELECT b FROM Bookmark b WHERE b.result.article = a)")
  List<Long> findDeletableArticleIds(LocalDateTime cutoff);
}
