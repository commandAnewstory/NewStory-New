package com.newstory.newstorybackend.domain.news.repository;

import com.newstory.newstorybackend.domain.news.entity.ArticleView;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface ArticleViewRepository extends JpaRepository<ArticleView, Long> {

  @Modifying
  @Query("DELETE FROM ArticleView v WHERE v.article.id IN :articleIds")
  void deleteByArticleIdIn(List<Long> articleIds);
}
