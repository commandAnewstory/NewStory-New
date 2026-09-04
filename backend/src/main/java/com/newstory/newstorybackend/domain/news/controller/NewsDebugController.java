package com.newstory.newstorybackend.domain.news.controller;

import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.news.service.RssNewsCollector;
import com.newstory.newstorybackend.global.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Profile("local")
@RestController
@RequestMapping("/api/debug/news")
@RequiredArgsConstructor
public class NewsDebugController {

  private final NewsArticleRepository newsArticleRepository;
  private final RssNewsCollector rssNewsCollector;

  @GetMapping("/count")
  public ApiResponse<Long> count() {
    return ApiResponse.ok(newsArticleRepository.count());
  }

  @PostMapping("/collect")
  public ApiResponse<Integer> collect() {
    return ApiResponse.ok(rssNewsCollector.collectAll());
  }
}
