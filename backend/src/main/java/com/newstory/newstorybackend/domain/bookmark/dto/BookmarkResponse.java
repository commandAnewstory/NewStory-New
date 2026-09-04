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

  public BookmarkResponse(Bookmark bookmark) {
    this.bookmarkId = bookmark.getId();
    this.resultId = bookmark.getResult().getId();
    this.style = bookmark.getResult().getStyle();
    this.articleTitle = bookmark.getResult().getArticle().getTitle();
    this.bookmarkedAt = bookmark.getCreatedAt();
  }
}
