package com.newstory.newstorybackend.domain.crawling.dto;

import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CrawledArticle {

  private final String title;
  private final String content;
  private final String contentHtml;
  private final String originalUrl;
  private final List<String> imageUrls;
}
