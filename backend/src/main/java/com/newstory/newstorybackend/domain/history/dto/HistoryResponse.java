package com.newstory.newstorybackend.domain.history.dto;

import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import java.time.LocalDateTime;
import lombok.Getter;

@Getter
public class HistoryResponse {

  private final Long resultId;
  private final String style;
  private final String articleTitle;
  private final LocalDateTime createdAt;
  private final LocalDateTime viewedAt;
  private final String articleUrl;
  private final String level;

  public HistoryResponse(ConvertedResult result) {
    this.resultId = result.getId();
    this.style = result.getStyle();
    this.articleTitle = result.getArticle().getTitle();
    this.createdAt = result.getCreatedAt();
    this.viewedAt = result.getViewedAt();
    this.articleUrl = result.getArticle().getUrl();
    this.level = result.getLevel();
  }
}
