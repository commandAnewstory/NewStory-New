package com.newstory.newstorybackend.domain.convert.service;

import com.newstory.newstorybackend.domain.ai.client.ClaudeApiClient;
import com.newstory.newstorybackend.domain.ai.client.GemmaApiClient;
import com.newstory.newstorybackend.domain.ai.dto.VerificationResult;
import com.newstory.newstorybackend.domain.convert.dto.ConvertRequest;
import com.newstory.newstorybackend.domain.convert.dto.ConvertResponse;
import com.newstory.newstorybackend.domain.convert.dto.OriginalArticleResponse;
import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import com.newstory.newstorybackend.domain.convert.repository.ConvertedResultRepository;
import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
import com.newstory.newstorybackend.domain.crawling.service.CrawlingService;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConvertService {

  private static final int MAX_RETRY = 3;
  private static final String METHOD_GEMMA_VERIFIED = "gemma_verified";
  private static final String METHOD_CLAUDE_FALLBACK = "claude_fallback";

  private final CrawlingService crawlingService;
  private final GemmaApiClient gemmaApiClient;
  private final ClaudeApiClient claudeApiClient;
  private final NewsArticleRepository newsArticleRepository;
  private final ConvertedResultRepository convertedResultRepository;

  public OriginalArticleResponse getOriginal(String url) {
    CrawledArticle article = crawlingService.crawl(url);
    return new OriginalArticleResponse(
        article.getTitle(),
        article.getContent(),
        article.getContentHtml(),
        article.getOriginalUrl(),
        article.getImageUrls());
  }

  @Transactional
  public ConvertResponse convert(ConvertRequest request, User user) {
    CrawledArticle crawled = crawlingService.crawl(request.getUrl());

    NewsArticle article =
        newsArticleRepository
            .findByUrl(request.getUrl())
            .orElseGet(
                () ->
                    newsArticleRepository.save(
                        NewsArticle.builder()
                            .url(request.getUrl())
                            .title(crawled.getTitle())
                            .build()));

    ConversionOutcome outcome = runConversionPipeline(crawled, request.getStyle());

    ConvertedResult result =
        ConvertedResult.builder()
            .article(article)
            .user(user)
            .style(request.getStyle())
            .convertedText(outcome.convertedText)
            .verificationPassed(outcome.verificationPassed)
            .verificationMethod(outcome.verificationMethod)
            .retryCount(outcome.retryCount)
            .isFeed(false)
            .build();

    return new ConvertResponse(convertedResultRepository.save(result));
  }

  @Transactional(readOnly = true)
  public ConvertResponse getResult(Long resultId, User user) {
    ConvertedResult result =
        convertedResultRepository
            .findById(resultId)
            .orElseThrow(() -> new NotFoundException("변환 결과를 찾을 수 없습니다."));

    if (result.getUser() == null || !result.getUser().getId().equals(user.getId())) {
      throw new UnauthorizedException("접근 권한이 없습니다.");
    }

    return new ConvertResponse(result);
  }

  private ConversionOutcome runConversionPipeline(CrawledArticle crawled, String style) {
    String convertedText = null;
    int retryCount = 0;
    String issues = null;

    while (retryCount < MAX_RETRY) {
      String prompt =
          retryCount == 0
              ? crawled.getContent()
              : crawled.getContent() + "\n\n[이전 변환에서 발견된 문제 — 반드시 수정할 것]\n" + issues;

      try {
        convertedText = gemmaApiClient.convert(prompt, style);
      } catch (Exception e) {
        log.warn("Gemma 실패, Claude로 fallback: {}", e.getMessage());
        String fallbackText = claudeApiClient.convert(crawled.getContent(), style);
        return new ConversionOutcome(fallbackText, false, METHOD_CLAUDE_FALLBACK, retryCount);
      }

      VerificationResult verification = claudeApiClient.verify(crawled.getContent(), convertedText);

      if (verification.isPassed()) {
        return new ConversionOutcome(convertedText, true, METHOD_GEMMA_VERIFIED, retryCount);
      }

      issues = verification.getRawResponse();
      retryCount++;
      log.warn("변환 검증 실패 ({}/{}): {}", retryCount, MAX_RETRY, issues);
    }

    log.warn("Gemma 검증 최종 실패, Claude로 fallback");
    String fallbackText = claudeApiClient.convert(crawled.getContent(), style);
    return new ConversionOutcome(fallbackText, false, METHOD_CLAUDE_FALLBACK, retryCount);
  }

  private record ConversionOutcome(
      String convertedText,
      boolean verificationPassed,
      String verificationMethod,
      int retryCount) {}
}
