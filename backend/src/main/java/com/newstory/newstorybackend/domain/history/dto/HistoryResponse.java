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

  /** 기사 카테고리 — 보관함·히스토리 카테고리 필터용. 직접 변환한 기사는 null */
  private final String category;

  public HistoryResponse(ConvertedResult result) {
    this.resultId = result.getId();
    this.style = result.getStyle();
    this.articleTitle = result.getArticle().getTitle();
    this.createdAt = result.getCreatedAt();
    this.viewedAt = result.getViewedAt();
    this.articleUrl = result.getArticle().getUrl();
    this.level = result.getLevel();
    this.category = result.getArticle().getCategory();
  }
}
