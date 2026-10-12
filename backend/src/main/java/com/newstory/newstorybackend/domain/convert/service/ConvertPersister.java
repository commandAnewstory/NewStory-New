package com.newstory.newstorybackend.domain.convert.service;

import com.newstory.newstorybackend.domain.convert.dto.ConvertResponse;
import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import com.newstory.newstorybackend.domain.convert.repository.ConversionCacheRepository;
import com.newstory.newstorybackend.domain.convert.repository.ConvertedResultRepository;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.domain.user.repository.UserRepository;
import com.newstory.newstorybackend.global.common.GlossaryParser;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * 변환 흐름의 DB 쓰기만 모아둔 곳. AI 호출(수십 초)이 DB 트랜잭션을 붙잡지 않도록 {@link ConvertService}는 트랜잭션 없이 돌고, 저장만 여기서 짧은
 * 트랜잭션으로 처리한다. UNIQUE 위반은 호출하는 쪽에서 잡아서 재조회한다 — 트랜잭션 안에서 잡으면 이미 rollback-only 라서 이어서 쓸 수 없다.
 */
@Component
@RequiredArgsConstructor
class ConvertPersister {

  private final NewsArticleRepository newsArticleRepository;
  private final ConversionCacheRepository conversionCacheRepository;
  private final ConvertedResultRepository convertedResultRepository;
  private final UserRepository userRepository;

  @Transactional
  public NewsArticle saveArticle(String url, String title) {
    return newsArticleRepository.saveAndFlush(NewsArticle.builder().url(url).title(title).build());
  }

  @Transactional
  public ConversionCache saveCache(
      NewsArticle article, String style, String level, ConversionOutcome outcome) {
    GlossaryParser.ParsedContent parsed = GlossaryParser.parse(outcome.convertedText());
    return conversionCacheRepository.saveAndFlush(
        ConversionCache.builder()
            .article(article)
            .style(style)
            .level(level)
            .convertedText(parsed.plainText())
            .glossary(parsed.glossary())
            .verificationPassed(outcome.verificationPassed())
            .verificationMethod(outcome.verificationMethod())
            .retryCount(outcome.retryCount())
            .build());
  }

  /** 사용자별 결과 행 저장 + 마지막 용어 난이도 갱신. 인증 필터가 넘겨준 User는 detached라 여기서 다시 읽어야 변경이 저장된다. */
  @Transactional
  public ConvertResponse recordResult(
      Long userId, Long articleId, String style, String level, Long cacheId, boolean cacheHit) {
    User user =
        userRepository.findById(userId).orElseThrow(() -> new NotFoundException("사용자를 찾을 수 없습니다."));
    if (!level.equals(user.getLastGlossaryLevel())) {
      user.updateLastGlossaryLevel(level);
    }

    NewsArticle article = newsArticleRepository.getReferenceById(articleId);
    ConversionCache cache =
        conversionCacheRepository
            .findById(cacheId)
            .orElseThrow(() -> new NotFoundException("변환 결과를 찾을 수 없습니다."));

    ConvertedResult result =
        convertedResultRepository.save(
            ConvertedResult.builder()
                .article(article)
                .user(user)
                .style(style)
                .convertedText(cache.getConvertedText())
                .verificationPassed(cache.getVerificationPassed())
                .verificationMethod(cache.getVerificationMethod())
                .retryCount(cache.getRetryCount())
                .isFeed(false)
                .build());

    return new ConvertResponse(result, cacheHit, cache.getGlossary());
  }

  record ConversionOutcome(
      String convertedText,
      boolean verificationPassed,
      String verificationMethod,
      int retryCount) {}
}
