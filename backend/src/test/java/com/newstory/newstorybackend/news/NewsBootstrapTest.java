package com.newstory.newstorybackend.news;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.newstory.newstorybackend.domain.news.client.RssFeedClient;
import com.newstory.newstorybackend.domain.news.dto.RssItem;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.news.service.RssNewsCollector;
import com.newstory.newstorybackend.domain.scheduler.NewsBootstrap;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class NewsBootstrapTest {

  private final RssFeedClient feed = mock(RssFeedClient.class);
  private final NewsArticleRepository repo = mock(NewsArticleRepository.class);
  private final List<NewsArticle> saved = new ArrayList<>();
  private final LocalDateTime now = LocalDateTime.now();

  @BeforeEach
  void setUp() {
    when(repo.existsByUrl(anyString())).thenReturn(false);
    when(repo.save(any()))
        .thenAnswer(
            inv -> {
              saved.add(inv.getArgument(0));
              return inv.getArgument(0);
            });
    // 첫 피드에만 기사 3개(1시간 전 / 3일 전 / 발행일 없음), 나머지 피드는 비어 있음
    when(feed.fetch(anyString(), anyString(), anyString(), anyString())).thenReturn(List.of());
    when(feed.fetch(
            "https://www.chosun.com/arc/outboundfeeds/rss/?outputType=xml", "조선일보", "전체", "rss"))
        .thenReturn(
            List.of(
                item("fresh", now.minusHours(1)),
                item("old", now.minusDays(3)),
                item("nodate", null)));
  }

  private RssItem item(String id, LocalDateTime publishedAt) {
    return RssItem.builder()
        .title(id)
        .link("https://a.example/" + id)
        .source("조선일보")
        .category("정치")
        .sourceType("rss")
        .publishedAt(publishedAt)
        .build();
  }

  private List<String> savedTitles() {
    return saved.stream().map(NewsArticle::getTitle).toList();
  }

  @Test
  void collectSince는_기준일보다_오래된_기사만_건너뛴다() {
    int n = new RssNewsCollector(feed, repo).collectSince(now.minusDays(2));

    assertThat(n).isEqualTo(2);
    assertThat(savedTitles()).containsExactly("fresh", "nodate");
  }

  @Test
  void collectAll은_날짜_상관없이_전부_저장한다() {
    new RssNewsCollector(feed, repo).collectAll();

    assertThat(savedTitles()).containsExactly("fresh", "old", "nodate");
  }

  private NewsBootstrap bootstrap(RssNewsCollector collector, boolean enabled) {
    NewsBootstrap b = new NewsBootstrap(repo, collector);
    ReflectionTestUtils.setField(b, "enabled", enabled);
    ReflectionTestUtils.setField(b, "days", 2);
    return b;
  }

  @Test
  void 기사가_0건이면_서버_뜰때_최근_2일치를_채운다() {
    when(repo.count()).thenReturn(0L);

    bootstrap(new RssNewsCollector(feed, repo), true).fillIfEmpty();

    assertThat(savedTitles()).containsExactly("fresh", "nodate");
  }

  @Test
  void 기사가_이미_있으면_재시작해도_수집_안_함() {
    when(repo.count()).thenReturn(5L);
    RssNewsCollector collector = mock(RssNewsCollector.class);

    bootstrap(collector, true).fillIfEmpty();

    verify(collector, never()).collectSince(any());
  }

  @Test
  void 꺼져_있으면_수집_안_함() {
    when(repo.count()).thenReturn(0L);
    RssNewsCollector collector = mock(RssNewsCollector.class);

    bootstrap(collector, false).fillIfEmpty();

    verify(collector, never()).collectSince(any());
  }

  @Test
  void 수집이_실패해도_서버_시작을_막지_않는다() {
    when(repo.count()).thenReturn(0L);
    RssNewsCollector collector = mock(RssNewsCollector.class);
    when(collector.collectSince(any())).thenThrow(new IllegalStateException("network"));

    bootstrap(collector, true).fillIfEmpty();
  }
}
