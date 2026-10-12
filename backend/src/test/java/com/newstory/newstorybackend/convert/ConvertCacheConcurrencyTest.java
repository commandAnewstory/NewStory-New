package com.newstory.newstorybackend.convert;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.newstory.newstorybackend.domain.ai.dto.VerificationResult;
import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ConvertCacheConcurrencyTest extends IntegrationTestSupport {

  static final String URL = "https://news.example.com/article/cache";

  @BeforeEach
  void stubExternalCalls() {
    given(crawlingService.crawl(URL))
        .willReturn(new CrawledArticle("캐시 테스트 기사", "원문 본문", "<p>원문</p>", URL, List.of()));
    given(gemmaApiClient.convert(anyString(), anyString(), anyString()))
        .willAnswer(
            invocation -> {
              Thread.sleep(300); // 실제 AI 호출처럼 시간이 걸려야 동시 요청이 겹친다
              return "변환 결과 " + invocation.getArgument(2);
            });
    given(claudeApiClient.verify(anyString(), anyString())).willReturn(VerificationResult.passed());
  }

  private Res convert(String token, String level) {
    return post("/api/convert", Map.of("url", URL, "style", "novel", "level", level), token);
  }

  private int cacheRows() {
    return jdbcTemplate.queryForObject("select count(*) from conversion_cache", Integer.class);
  }

  @Test
  void 캐시_히트면_원문을_다시_크롤링하지_않는다() {
    String token = signupAndLogin("hit@newstory.test").accessToken();
    assertThat(convert(token, "MEDIUM").status()).isEqualTo(200);
    clearInvocations(crawlingService, gemmaApiClient, claudeApiClient);

    Res second = convert(token, "MEDIUM");

    assertThat(second.status()).isEqualTo(200);
    assertThat((Boolean) second.json("$.data.cachedResult")).isTrue();
    verify(crawlingService, never()).crawl(anyString());
    verify(gemmaApiClient, never()).convert(anyString(), anyString(), anyString());
  }

  @Test
  void 같은_요청이_동시에_10개_와도_AI는_한번만_부르고_전부_200() throws Exception {
    String token = signupAndLogin("burst@newstory.test").accessToken();
    int requests = 10;
    ExecutorService pool = Executors.newFixedThreadPool(requests);
    CountDownLatch start = new CountDownLatch(1);
    List<Future<Res>> futures = new ArrayList<>();
    for (int i = 0; i < requests; i++) {
      futures.add(
          pool.submit(
              () -> {
                start.await();
                return convert(token, "MEDIUM");
              }));
    }
    start.countDown();

    List<Integer> statuses = new ArrayList<>();
    for (Future<Res> f : futures) {
      statuses.add(f.get().status());
    }
    pool.shutdown();

    assertThat(statuses).containsOnly(200);
    verify(gemmaApiClient, times(1)).convert(anyString(), eq("novel"), eq("MEDIUM"));
    assertThat(cacheRows()).isEqualTo(1);
    assertThat(jdbcTemplate.queryForObject("select count(*) from news_articles", Integer.class))
        .isEqualTo(1);
  }

  @Test
  void 레벨이_다르면_각각_따로_변환한다() {
    String token = signupAndLogin("levels@newstory.test").accessToken();

    Res low = convert(token, "LOW");
    Res high = convert(token, "HIGH");

    assertThat((String) low.json("$.data.convertedText")).isEqualTo("변환 결과 LOW");
    assertThat((String) high.json("$.data.convertedText")).isEqualTo("변환 결과 HIGH");
    assertThat(cacheRows()).isEqualTo(2);
  }

  @Test
  void 변환할_때_고른_레벨이_사용자의_마지막_레벨로_저장된다() {
    String token = signupAndLogin("lastlevel@newstory.test").accessToken();

    convert(token, "LOW");

    Res me = get("/api/users/me", token);
    assertThat((String) me.json("$.data.lastGlossaryLevel")).isEqualTo("LOW");
  }

  @Test
  void 다른_서버가_먼저_캐시를_저장해도_500_대신_그_캐시를_돌려준다() {
    String token = signupAndLogin("safetynet@newstory.test").accessToken();
    given(gemmaApiClient.convert(anyString(), anyString(), anyString()))
        .willAnswer(
            invocation -> {
              // 이 서버가 AI 응답을 기다리는 사이, 다른 서버가 같은 키로 먼저 저장했다고 가정
              Long articleId =
                  jdbcTemplate.queryForObject(
                      "select id from news_articles where url = ?", Long.class, URL);
              jdbcTemplate.update(
                  "insert into conversion_cache (article_id, style, level, converted_text,"
                      + " verification_passed, retry_count) values (?, 'novel', 'MEDIUM', ?, true, 0)",
                  articleId,
                  "다른 서버가 저장한 결과");
              return "이 서버의 결과";
            });

    Res res = convert(token, "MEDIUM");

    assertThat(res.status()).isEqualTo(200);
    assertThat((String) res.json("$.data.convertedText")).isEqualTo("다른 서버가 저장한 결과");
    assertThat(cacheRows()).isEqualTo(1);
  }
}
