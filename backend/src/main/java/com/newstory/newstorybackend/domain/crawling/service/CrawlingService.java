package com.newstory.newstorybackend.domain.crawling.service;

import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class CrawlingService {

  public CrawledArticle crawl(String url) {
    try {
      Document doc = Jsoup.connect(url).timeout(10_000).get();

      String title = doc.title();
      String contentHtml =
          doc.select("article, .article-body, #article-view-content-div, .news_body").html();
      if (contentHtml.isBlank()) {
        contentHtml = doc.body().html();
      }
      String content = Jsoup.parse(contentHtml).text();

      List<String> imageUrls =
          doc.select("img[src]").stream()
              .map(img -> img.absUrl("src"))
              .filter(src -> !src.isBlank())
              .limit(5)
              .toList();

      return new CrawledArticle(title, content, contentHtml, url, imageUrls);
    } catch (Exception e) {
      log.error("크롤링 실패: {}", url, e);
      throw new RuntimeException("기사를 불러올 수 없습니다: " + url, e);
    }
  }
}
