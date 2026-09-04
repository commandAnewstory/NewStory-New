package com.newstory.newstorybackend.domain.news.controller;

import com.newstory.newstorybackend.domain.news.dto.NewsItem;
import com.newstory.newstorybackend.domain.news.service.NewsService;
import com.newstory.newstorybackend.global.common.ApiResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
public class NewsController {

  private final NewsService newsService;

  @GetMapping
  public ApiResponse<List<NewsItem>> getNews(
      @RequestParam(required = false) String category,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    return ApiResponse.ok(newsService.getNews(category, page, size));
  }

  @GetMapping("/categories")
  public ApiResponse<List<String>> getCategories() {
    return ApiResponse.ok(newsService.getCategories());
  }

  @GetMapping("/popular")
  public ApiResponse<List<NewsItem>> getPopular(@RequestParam(defaultValue = "10") int limit) {
    return ApiResponse.ok(newsService.getPopular(limit));
  }

  @PostMapping("/{id}/view")
  public ApiResponse<Void> recordView(@PathVariable Long id) {
    newsService.recordView(id);
    return ApiResponse.ok();
  }
}
