package com.newstory.newstorybackend.domain.news.dto;

import java.util.List;
import lombok.Getter;
import org.springframework.data.domain.Page;

@Getter
public class NewsPageResponse {

  private final List<NewsItem> content;
  private final int page;
  private final int size;
  private final long totalElements;
  private final int totalPages;

  public NewsPageResponse(Page<NewsItem> page) {
    this.content = page.getContent();
    this.page = page.getNumber();
    this.size = page.getSize();
    this.totalElements = page.getTotalElements();
    this.totalPages = page.getTotalPages();
  }
}
