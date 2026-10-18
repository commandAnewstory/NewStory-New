package com.newstory.newstorybackend.domain.convert.service;

import com.newstory.newstorybackend.domain.ai.client.ClaudeApiClient;
import com.newstory.newstorybackend.domain.ai.client.GemmaApiClient;
import com.newstory.newstorybackend.domain.ai.dto.VerificationResult;
import com.newstory.newstorybackend.domain.bookmark.repository.BookmarkRepository;
import com.newstory.newstorybackend.domain.convert.dto.ConvertRequest;
import com.newstory.newstorybackend.domain.convert.dto.ConvertResponse;
import com.newstory.newstorybackend.domain.convert.dto.GlossaryItem;
import com.newstory.newstorybackend.domain.convert.dto.OriginalArticleResponse;
import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import com.newstory.newstorybackend.domain.convert.repository.ConversionCacheRepository;
import com.newstory.newstorybackend.domain.convert.repository.ConvertedResultRepository;
import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
import com.newstory.newstorybackend.domain.crawling.service.CrawlingService;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConvertService {

  private static final int MAX_RETRY = 3;
  private static final String METHOD_GEMMA_VERIFIED = "gemma_verified";
  private static final String METHOD_CLAUDE_FALLBACK = "claude_fallback";
  private static final String DEFAULT_LEVEL = "MEDIUM";

  private final CrawlingService crawlingService;
  private final GemmaApiClient gemmaApiClient;
  private final ClaudeApiClient claudeApiClient;
  private final NewsArticleRepository newsArticleRepository;
  private final ConvertedResultRepository convertedResultRepository;
  private final ConversionCacheRepository conversionCacheRepository;
  private final ConvertPersister convertPersister;
  private final BookmarkRepository bookmarkRepository;
  private final ConcurrentHashMap<String, Object> inFlight = new ConcurrentHashMap<>();

  public OriginalArticleResponse getOriginal(String url) {
    CrawledArticle article = crawlingService.crawl(url);
    return new OriginalArticleResponse(
        article.getTitle(),
        article.getContent(),
        article.getContentHtml(),
        article.getOriginalUrl(),
        article.getImageUrls());
  }

  /**
   * 1) 기사+스타일+레벨 캐시가 있으면 크롤링·AI 없이 바로 응답한다. 2) 없으면 같은 키의 동시 요청을 하나로 묶어 AI를 한 번만 부른다. 3) 그래도 (서버가 여러
   * 대일 때 등) 저장이 겹치면 UNIQUE 위반을 잡아 먼저 저장된 캐시를 쓴다.
   */
  public ConvertResponse convert(ConvertRequest request, User user) {
    String level = resolveLevel(request.getLevel(), user);
    String style = request.getStyle();
    String url = request.getUrl();

    CacheRef ref = findCached(url, style, level);
    boolean cacheHit = ref != null;

    if (ref == null) {
      String key = url + "\n" + style + "\n" + level;
      Object lock = inFlight.computeIfAbsent(key, k -> new Object());
      try {
        synchronized (lock) {
          ref = findCached(url, style, level);
          if (ref != null) {
            cacheHit = true;
          } else {
            ref = convertAndStore(url, style, level);
          }
        }
      } finally {
        inFlight.remove(key, lock);
      }
    }

    return convertPersister.recordResult(
        user.getId(), ref.articleId(), style, level, ref.cacheId(), cacheHit);
  }

  private CacheRef findCached(String url, String style, String level) {
    return newsArticleRepository
        .findByUrl(url)
        .flatMap(
            article ->
                conversionCacheRepository
                    .findByArticleIdAndStyleAndLevel(article.getId(), style, level)
                    .map(cache -> new CacheRef(article.getId(), cache.getId())))
        .orElse(null);
  }

  private CacheRef convertAndStore(String url, String style, String level) {
    CrawledArticle crawled = crawlingService.crawl(url);
    NewsArticle article =
        newsArticleRepository
            .findByUrl(url)
            .orElseGet(() -> saveArticleOrReuse(url, crawled.getTitle()));

    ConvertPersister.ConversionOutcome outcome = runConversionPipeline(crawled, style, level);

    ConversionCache cache;
    try {
      cache = convertPersister.saveCache(article, style, level, outcome);
    } catch (DataIntegrityViolationException e) {
      cache =
          conversionCacheRepository
              .findByArticleIdAndStyleAndLevel(article.getId(), style, level)
              .orElseThrow(() -> e);
    }
    return new CacheRef(article.getId(), cache.getId());
  }

  private NewsArticle saveArticleOrReuse(String url, String title) {
    try {
      return convertPersister.saveArticle(url, title);
    } catch (DataIntegrityViolationException e) {
      return newsArticleRepository.findByUrl(url).orElseThrow(() -> e);
    }
  }

  private record CacheRef(Long articleId, Long cacheId) {}

  @Transactional(readOnly = true)
  public ConvertResponse getResult(Long resultId, User user) {
    ConvertedResult result =
        convertedResultRepository
            .findById(resultId)
            .orElseThrow(() -> new NotFoundException("변환 결과를 찾을 수 없습니다."));

    if (result.getUser() == null || !result.getUser().getId().equals(user.getId())) {
      throw new UnauthorizedException("접근 권한이 없습니다.");
    }

    List<GlossaryItem> glossary =
        conversionCacheRepository
            .findByArticleIdAndStyleAndLevel(
                result.getArticle().getId(), result.getStyle(), result.getLevel())
            .map(ConversionCache::getGlossary)
            .orElse(List.of());
    boolean bookmarked = bookmarkRepository.existsByUserIdAndResultId(user.getId(), resultId);
    return new ConvertResponse(result, false, glossary, bookmarked);
  }

  private String resolveLevel(String requestLevel, User user) {
    if (requestLevel != null && !requestLevel.isBlank()) {
      return requestLevel;
    }
    String userLevel = user.getLastGlossaryLevel();
    return (userLevel != null && !userLevel.isBlank()) ? userLevel : DEFAULT_LEVEL;
  }

  private ConvertPersister.ConversionOutcome runConversionPipeline(
      CrawledArticle crawled, String style, String level) {
    String convertedText = null;
    int retryCount = 0;
    String issues = null;

    while (retryCount < MAX_RETRY) {
      String prompt =
          retryCount == 0
              ? crawled.getContent()
              : crawled.getContent() + "\n\n[이전 변환에서 발견된 문제 — 반드시 수정할 것]\n" + issues;

      try {
        convertedText = gemmaApiClient.convert(prompt, style, level);
      } catch (Exception e) {
        log.warn("Gemma 실패, Claude로 fallback: {}", e.getMessage());
        String fallbackText = claudeApiClient.convert(crawled.getContent(), style, level);
        return new ConvertPersister.ConversionOutcome(
            fallbackText, false, METHOD_CLAUDE_FALLBACK, retryCount);
      }

      VerificationResult verification = claudeApiClient.verify(crawled.getContent(), convertedText);

      if (verification.isPassed()) {
        return new ConvertPersister.ConversionOutcome(
            convertedText, true, METHOD_GEMMA_VERIFIED, retryCount);
      }

      issues = verification.getRawResponse();
      retryCount++;
      log.warn("변환 검증 실패 ({}/{}): {}", retryCount, MAX_RETRY, issues);
    }

    log.warn("Gemma 검증 최종 실패, Claude로 fallback");
    String fallbackText = claudeApiClient.convert(crawled.getContent(), style, level);
    return new ConvertPersister.ConversionOutcome(
        fallbackText, false, METHOD_CLAUDE_FALLBACK, retryCount);
  }
}
