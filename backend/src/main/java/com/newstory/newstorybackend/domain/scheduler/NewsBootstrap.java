package com.newstory.newstorybackend.domain.scheduler;

import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.news.service.RssNewsCollector;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 새 서버에 처음 띄웠을 때 기사가 하나도 없으면 다음 정각 스케줄러까지 빈 화면이라, 서버가 뜬 직후 최근 N일치를 한 번 채운다. 기사가 이미 있으면 아무것도 안 함
 * (재시작할 때마다 수집하지 않게). 정각 스케줄러는 그대로.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NewsBootstrap {

  private final NewsArticleRepository newsArticleRepository;
  private final RssNewsCollector rssNewsCollector;

  @Value("${newstory.bootstrap.enabled:true}")
  private boolean enabled;

  @Value("${newstory.bootstrap.days:2}")
  private int days;

  @EventListener(ApplicationReadyEvent.class)
  public void fillIfEmpty() {
    if (!enabled || newsArticleRepository.count() > 0) {
      return;
    }
    log.info("기사 0건 → 최근 {}일치 초기 수집 시작", days);
    try {
      int saved = rssNewsCollector.collectSince(LocalDateTime.now().minusDays(days));
      log.info("초기 수집 완료: {}건", saved);
    } catch (RuntimeException e) {
      log.warn("초기 수집 실패 — 정각 스케줄러가 이어서 수집함", e);
    }
  }
}
