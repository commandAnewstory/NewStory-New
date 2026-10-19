package com.newstory.newstorybackend.news;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.newstory.newstorybackend.domain.news.client.RssFeedClient;
import com.newstory.newstorybackend.domain.news.dto.RssItem;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.news.service.RssNewsCollector;
import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/** 실제 PostgreSQL에 저장 — AWS 첫 배포 때 URL 하나 때문에 수집이 통째로 롤백된 문제 재현 */
class RssCollectSaveTest extends IntegrationTestSupport {

  @Autowired NewsArticleRepository newsArticleRepository;

  private final RssFeedClient feed = mock(RssFeedClient.class);

  private RssItem item(String link, String title) {
    return RssItem.builder()
        .title(title)
        .link(link)
        .source("조선일보")
        .category("정치")
        .sourceType("rss")
        .publishedAt(LocalDateTime.now().minusHours(1))
        .build();
  }

  private List<String> savedTitles() {
    return newsArticleRepository.findAll().stream().map(NewsArticle::getTitle).sorted().toList();
  }

  private int collectWith(List<RssItem> firstFeed) {
    when(feed.fetch(anyString(), anyString(), anyString(), anyString())).thenReturn(List.of());
    when(feed.fetch(
            "https://www.chosun.com/arc/outboundfeeds/rss/?outputType=xml", "조선일보", "전체", "rss"))
        .thenReturn(firstFeed);
    return new RssNewsCollector(feed, newsArticleRepository).collectAll();
  }

  @Test
  void 인덱스_한계를_넘는_긴_URL은_건너뛰고_나머지는_저장한다() {
    String hugeUrl = "https://news.google.com/rss/articles/" + "A".repeat(3400);

    int saved =
        collectWith(
            List.of(
                item("https://a.example/1", "앞 기사"),
                item(hugeUrl, "긴 URL"),
                item("https://a.example/2", "뒤 기사")));

    assertThat(saved).isEqualTo(2);
    assertThat(savedTitles()).containsExactly("뒤 기사", "앞 기사");
  }

  @Test
  void 기사_하나가_DB_에러를_내도_나머지는_저장된다() {
    String tooLongTitle = "가".repeat(600); // title 컬럼 500자 초과 → DB 에러

    int saved =
        collectWith(
            List.of(
                item("https://a.example/1", "앞 기사"),
                item("https://a.example/bad", tooLongTitle),
                item("https://a.example/2", "뒤 기사")));

    assertThat(saved).isEqualTo(2);
    assertThat(savedTitles()).containsExactly("뒤 기사", "앞 기사");
  }

  @Test
  void 같은_피드를_다시_수집하면_중복_저장_안_함() {
    List<RssItem> items = List.of(item("https://a.example/1", "앞 기사"));
    collectWith(items);

    assertThat(collectWith(items)).isZero();
    assertThat(newsArticleRepository.count()).isEqualTo(1);
  }
}
