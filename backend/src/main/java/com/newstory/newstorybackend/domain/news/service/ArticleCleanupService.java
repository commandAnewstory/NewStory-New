package com.newstory.newstorybackend.domain.news.service;

import com.newstory.newstorybackend.domain.convert.repository.ConversionCacheRepository;
import com.newstory.newstorybackend.domain.convert.repository.ConvertedResultRepository;
import com.newstory.newstorybackend.domain.news.repository.ArticleViewRepository;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ArticleCleanupService {

  private final NewsArticleRepository newsArticleRepository;
  private final ArticleViewRepository articleViewRepository;
  private final ConversionCacheRepository conversionCacheRepository;
  private final ConvertedResultRepository convertedResultRepository;

  @Transactional
  public int deleteOldUnbookmarkedArticles() {
    LocalDateTime cutoff = LocalDateTime.now().minusMonths(1);
    List<Long> ids = newsArticleRepository.findDeletableArticleIds(cutoff);

    if (ids.isEmpty()) {
      log.info("삭제 대상 기사 없음 (publishedAt < {}, 북마크 없는 것만)", cutoff);
      return 0;
    }

    log.info("삭제 대상 기사 {}건 (publishedAt < {}, 북마크 없는 것만) — 삭제 시작", ids.size(), cutoff);

    articleViewRepository.deleteByArticleIdIn(ids);
    conversionCacheRepository.deleteByArticleIdIn(ids);
    convertedResultRepository.deleteByArticleIdIn(ids);
    newsArticleRepository.deleteAllByIdInBatch(ids);

    log.info("기사 삭제 완료: {}건", ids.size());
    return ids.size();
  }
}
