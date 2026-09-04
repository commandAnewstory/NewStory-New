package com.newstory.newstorybackend.domain.news.repository;

import com.newstory.newstorybackend.domain.news.entity.ArticleView;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ArticleViewRepository extends JpaRepository<ArticleView, Long> {}
