package com.newstory.newstorybackend.domain.bookmark.dto;

import com.newstory.newstorybackend.domain.bookmark.entity.Bookmark;
import java.time.LocalDateTime;
import lombok.Getter;

@Getter
public class BookmarkResponse {

  private final Long bookmarkId;
  private final Long resultId;
  private final String style;
  private final String articleTitle;
  private final LocalDateTime bookmarkedAt;
  private final String articleUrl;
  private final String level;

  /** 기사 카테고리 — 보관함·히스토리 카테고리 필터용. 직접 변환한 기사는 null */
  private final String category;

  public BookmarkResponse(Bookmark bookmark) {
    this.bookmarkId = bookmark.getId();
    this.resultId = bookmark.getResult().getId();
    this.style = bookmark.getResult().getStyle();
    this.articleTitle = bookmark.getResult().getArticle().getTitle();
    this.bookmarkedAt = bookmark.getCreatedAt();
    this.articleUrl = bookmark.getResult().getArticle().getUrl();
    this.level = bookmark.getResult().getLevel();
    this.category = bookmark.getResult().getArticle().getCategory();
  }
}
