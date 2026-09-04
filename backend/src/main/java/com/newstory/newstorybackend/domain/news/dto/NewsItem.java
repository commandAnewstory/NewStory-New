package com.newstory.newstorybackend.domain.news.dto;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import java.time.LocalDateTime;
import lombok.Getter;

@Getter
public class NewsItem {

  private final Long id;
  private final String title;
  private final String description;
  private final String url;
  private final String source;
  private final String category;
  private final String sourceType;
  private final LocalDateTime publishedAt;

  public NewsItem(NewsArticle article) {
    this.id = article.getId();
    this.title = article.getTitle();
    this.description = article.getDescription();
    this.url = article.getUrl();
    this.source = article.getSource();
    this.category = article.getCategory();
    this.sourceType = article.getSourceType();
    this.publishedAt = article.getPublishedAt();
  }
}
