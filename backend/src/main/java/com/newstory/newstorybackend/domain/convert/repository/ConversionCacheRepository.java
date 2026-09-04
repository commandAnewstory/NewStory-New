package com.newstory.newstorybackend.domain.convert.repository;

import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ConversionCacheRepository extends JpaRepository<ConversionCache, Long> {

  Optional<ConversionCache> findByArticleIdAndStyleAndLevel(
      Long articleId, String style, String level);

  boolean existsByArticleIdAndStyleAndLevel(Long articleId, String style, String level);

  @Query(
      "SELECT c FROM ConversionCache c WHERE c.style = 'card' AND c.createdAt >= :since ORDER BY c.createdAt DESC")
  List<ConversionCache> findTodayCardCaches(LocalDateTime since, Pageable pageable);

  List<ConversionCache> findTop3ByStyleOrderByCreatedAtDesc(String style);
}
