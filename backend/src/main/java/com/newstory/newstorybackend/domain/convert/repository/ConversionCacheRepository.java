package com.newstory.newstorybackend.domain.convert.repository;

import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConversionCacheRepository extends JpaRepository<ConversionCache, Long> {

  Optional<ConversionCache> findByArticleIdAndStyle(Long articleId, String style);

  boolean existsByArticleIdAndStyle(Long articleId, String style);
}
