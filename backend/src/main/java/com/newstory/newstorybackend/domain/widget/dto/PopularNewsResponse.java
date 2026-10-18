package com.newstory.newstorybackend.domain.widget.dto;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import lombok.Getter;

/** 위젯 "관심 뉴스" 한 줄. 누르면 앱이 articleId 기사의 카드요약을 생성한다. */
@Getter
public class PopularNewsResponse {

  private final Long articleId;
  private final String title;
  private final String category;

  public PopularNewsResponse(NewsArticle article) {
    this.articleId = article.getId();
    this.title = article.getTitle();
    this.category = article.getCategory();
  }
}
