package com.newstory.newstorybackend.domain.convert.repository;

import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface ConvertedResultRepository extends JpaRepository<ConvertedResult, Long> {

  List<ConvertedResult> findByUserIdOrderByCreatedAtDesc(Long userId);

  @Modifying
  @Query("DELETE FROM ConvertedResult r WHERE r.article.id IN :articleIds")
  void deleteByArticleIdIn(List<Long> articleIds);
}
