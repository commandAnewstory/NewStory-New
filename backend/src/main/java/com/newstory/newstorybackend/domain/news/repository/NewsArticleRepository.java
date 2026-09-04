package com.newstory.newstorybackend.domain.news.repository;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
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

  @Query(
      "SELECT DISTINCT a.category FROM NewsArticle a WHERE a.category IS NOT NULL ORDER BY a.category")
  List<String> findDistinctCategories();
}
