package com.newstory.newstorybackend.domain.convert.repository;

import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConversionCacheRepository extends JpaRepository<ConversionCache, Long> {

  Optional<ConversionCache> findByArticleIdAndStyleAndLevel(
      Long articleId, String style, String level);

  boolean existsByArticleIdAndStyleAndLevel(Long articleId, String style, String level);
}
