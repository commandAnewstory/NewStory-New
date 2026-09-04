package com.newstory.newstorybackend.domain.news.service;

import com.newstory.newstorybackend.domain.news.client.RssFeedClient;
import com.newstory.newstorybackend.domain.news.dto.RssItem;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class RssNewsCollector {

  private final RssFeedClient rssFeedClient;
  private final NewsArticleRepository newsArticleRepository;

  /** RSS 소스 정의. {url, sourceName, category, sourceType} */
  private static final List<String[]> SOURCES =
      List.of(
          new String[] {"https://www.chosun.com/arc/outboundfeeds/rss/", "조선일보", "전체", "rss"},
          new String[] {"https://rss.joins.com/joins_news_list.xml", "중앙일보", "전체", "rss"},
          new String[] {"https://rss.donga.com/total.xml", "동아일보", "전체", "rss"},
          new String[] {"https://news.sbs.co.kr/news/RSS.xml", "SBS", "전체", "rss"},
          new String[] {"https://imnews.imbc.com/rss/news/news_00.xml", "MBC", "전체", "rss"},
          new String[] {
            "https://news.google.com/rss/search?q=기술+IT&hl=ko&gl=KR&ceid=KR:ko",
            "Google News",
            "IT",
            "google_news"
          },
          new String[] {
            "https://news.google.com/rss/search?q=정치&hl=ko&gl=KR&ceid=KR:ko",
            "Google News",
            "정치",
            "google_news"
          });

  @Transactional
  public int collectAll() {
    int saved = 0;
    for (String[] src : SOURCES) {
      String url = src[0], sourceName = src[1], category = src[2], sourceType = src[3];
      List<RssItem> items = rssFeedClient.fetch(url, sourceName, category, sourceType);
      for (RssItem item : items) {
        if (!newsArticleRepository.existsByUrl(item.getLink())) {
          newsArticleRepository.save(toEntity(item));
          saved++;
        }
      }
      log.debug("[{}] {}건 수집 완료", sourceName, items.size());
    }
    log.info("RSS 수집 완료: 신규 {}건 저장", saved);
    return saved;
  }

  private NewsArticle toEntity(RssItem item) {
    return NewsArticle.builder()
        .url(item.getLink())
        .title(item.getTitle())
        .description(item.getDescription())
        .source(item.getSource())
        .category(item.getCategory())
        .sourceType(item.getSourceType())
        .publishedAt(item.getPublishedAt())
        .build();
  }
}
