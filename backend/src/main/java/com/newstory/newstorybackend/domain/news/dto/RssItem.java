package com.newstory.newstorybackend.domain.news.dto;

import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class RssItem {

  private final String title;
  private final String link;
  private final String description;
  private final String source;
  private final String category;
  private final String sourceType;
  private final LocalDateTime publishedAt;
}
