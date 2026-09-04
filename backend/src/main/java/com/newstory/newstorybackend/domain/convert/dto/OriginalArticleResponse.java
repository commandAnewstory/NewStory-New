package com.newstory.newstorybackend.domain.convert.dto;

import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class OriginalArticleResponse {

  private final String title;
  private final String content;
  private final String contentHtml;
  private final String originalUrl;
  private final List<String> imageUrls;
}
