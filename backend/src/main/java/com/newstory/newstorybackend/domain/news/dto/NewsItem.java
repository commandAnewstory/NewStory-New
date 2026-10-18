package com.newstory.newstorybackend.domain.news.dto;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.global.common.HtmlText;
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
    // 이미 HTML 그대로 저장된 예전 기사도 화면엔 텍스트만 나가게
    this.description = HtmlText.plain(article.getDescription());
    this.url = article.getUrl();
    this.source = article.getSource();
    this.category = article.getCategory();
    this.sourceType = article.getSourceType();
    this.publishedAt = article.getPublishedAt();
  }
}
