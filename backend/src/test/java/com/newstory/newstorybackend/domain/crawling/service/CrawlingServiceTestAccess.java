package com.newstory.newstorybackend.domain.crawling.service;

import org.jsoup.nodes.Document;

/** 테스트에서 package-private 추출 로직을 부르기 위한 통로. */
public class CrawlingServiceTestAccess {

  private final CrawlingService crawler = new CrawlingService();

  public String extractContent(Document doc) {
    return crawler.extractContent(doc, "https://test.example/article");
  }
}
