package com.newstory.newstorybackend.domain.news.service;

import com.newstory.newstorybackend.domain.news.client.RssFeedClient;
import com.newstory.newstorybackend.domain.news.dto.RssItem;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class RssNewsCollector {

  private final RssFeedClient rssFeedClient;
  private final NewsArticleRepository newsArticleRepository;

  /** RSS 소스 정의. {url, sourceName, category, sourceType} */
  private static final List<String[]> SOURCES =
      List.of(
          // 조선일보 — ?outputType=xml 없으면 404
          new String[] {
            "https://www.chosun.com/arc/outboundfeeds/rss/?outputType=xml", "조선일보", "전체", "rss"
          },
          // 동아일보 — 섹션별 피드로 카테고리 정확도 확보
          new String[] {"https://rss.donga.com/politics.xml", "동아일보", "정치", "rss"},
          new String[] {"https://rss.donga.com/economy.xml", "동아일보", "경제", "rss"},
          new String[] {"https://rss.donga.com/society.xml", "동아일보", "사회", "rss"},
          new String[] {"https://rss.donga.com/culture.xml", "동아일보", "문화", "rss"},
          new String[] {"https://rss.donga.com/sports.xml", "동아일보", "스포츠", "rss"},
          new String[] {"https://rss.donga.com/it.xml", "동아일보", "IT", "rss"},
          // SBS — SectionRssFeed 형식으로 교체 (구 RSS.xml는 404)
          new String[] {
            "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=01&plink=RSSREADER",
            "SBS",
            "정치",
            "rss"
          },
          new String[] {
            "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=02&plink=RSSREADER",
            "SBS",
            "경제",
            "rss"
          },
          new String[] {
            "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=03&plink=RSSREADER",
            "SBS",
            "사회",
            "rss"
          },
          // 중앙일보: RSS 서비스 종료 — 제거
          // MBC: RSS 폐지(에러 페이지 리다이렉트) — 제거
          // Google News — 검색 쿼리 기반, 카테고리는 소스 정의에서 결정
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

  /**
   * news_articles.url 유니크 인덱스(btree) 한계 2704바이트 안쪽으로. 넘는 URL(구글 뉴스 리다이렉트 등)은 저장하면 인덱스 에러가 나서 건너뛴다.
   */
  static final int MAX_URL_BYTES = 2000;

  /** 매시 정각 스케줄러용 — 피드에 있는 건 날짜 상관없이 전부 저장 */
  public int collectAll() {
    return collect(null);
  }

  /** [since] 이전에 발행된 기사는 건너뛰고 수집 (발행일 없는 기사는 저장). 빈 DB 초기 채우기용 */
  public int collectSince(LocalDateTime since) {
    return collect(since);
  }

  /** 기사 1건씩 따로 저장한다(save가 건마다 자체 트랜잭션). 예전엔 전체를 한 트랜잭션으로 묶어서 기사 하나가 DB 에러를 내면 그 회차 수집이 통째로 롤백됐다. */
  private int collect(LocalDateTime since) {
    int saved = 0;
    int skipped = 0;
    for (String[] src : SOURCES) {
      String url = src[0], sourceName = src[1], category = src[2], sourceType = src[3];
      List<RssItem> items = rssFeedClient.fetch(url, sourceName, category, sourceType);
      for (RssItem item : items) {
        if (since != null
            && item.getPublishedAt() != null
            && item.getPublishedAt().isBefore(since)) {
          continue;
        }
        String link = item.getLink();
        if (link == null
            || link.isBlank()
            || link.getBytes(StandardCharsets.UTF_8).length > MAX_URL_BYTES) {
          skipped++;
          continue;
        }
        try {
          if (!newsArticleRepository.existsByUrl(link)) {
            newsArticleRepository.save(toEntity(item));
            saved++;
          }
        } catch (DataAccessException e) {
          skipped++;
          log.warn("[{}] 기사 저장 실패, 건너뜀: {} ({})", sourceName, item.getTitle(), e.getMessage());
        }
      }
      log.debug("[{}] {}건 수집 완료", sourceName, items.size());
    }
    log.info("RSS 수집 완료: 신규 {}건 저장, {}건 건너뜀", saved, skipped);
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
