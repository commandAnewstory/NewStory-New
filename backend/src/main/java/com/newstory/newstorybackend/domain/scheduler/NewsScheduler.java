package com.newstory.newstorybackend.domain.scheduler;

import com.newstory.newstorybackend.domain.news.service.RssNewsCollector;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class NewsScheduler {

  private final RssNewsCollector rssNewsCollector;

  @Scheduled(cron = "0 0 * * * *")
  public void collectNews() {
    log.info("RSS 수집 스케줄러 시작");
    rssNewsCollector.collectAll();
  }
}
