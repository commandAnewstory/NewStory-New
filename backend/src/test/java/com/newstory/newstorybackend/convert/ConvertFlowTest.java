package com.newstory.newstorybackend.convert;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import com.newstory.newstorybackend.domain.ai.dto.VerificationResult;
import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
import com.newstory.newstorybackend.domain.crawling.exception.ArticleContentUnavailableException;
import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ConvertFlowTest extends IntegrationTestSupport {

  static final String URL = "https://news.example.com/article/1";

  @BeforeEach
  void stubExternalCalls() {
    given(crawlingService.crawl(URL))
        .willReturn(new CrawledArticle("테스트 기사", "원문 본문입니다.", "<p>원문</p>", URL, List.of()));
    given(gemmaApiClient.convert(anyString(), anyString(), anyString()))
        .willReturn("- 첫째 줄 {{term:금리|돈을 빌린 대가}} 설명\n- 둘째 줄");
    given(claudeApiClient.verify(anyString(), anyString())).willReturn(VerificationResult.passed());
  }

  @Test
  void 변환하면_용어풀이와_읽기시간이_붙고_마킹문법은_본문에서_빠진다() {
    Tokens tokens = signupAndLogin("convert@newstory.test");

    Res res =
        post(
            "/api/convert",
            Map.of("url", URL, "style", "card", "level", "MEDIUM"),
            tokens.accessToken());

    assertThat(res.status()).isEqualTo(200);
    assertThat((String) res.json("$.data.convertedText")).doesNotContain("{{").contains("금리");
    assertThat((String) res.json("$.data.glossary[0].term")).isEqualTo("금리");
    assertThat((String) res.json("$.data.glossary[0].definition")).isEqualTo("돈을 빌린 대가");
    assertThat((String) res.json("$.data.readingTimeLabel")).isNotBlank();
    assertThat((Boolean) res.json("$.data.verificationPassed")).isTrue();
  }

  @Test
  void 로그인하지_않으면_변환할_수_없다() {
    Res res = post("/api/convert", Map.of("url", URL, "style", "card"), null);

    assertThat(res.status()).isEqualTo(401);
  }

  @Test
  void 지원하지_않는_스타일이면_400() {
    Tokens tokens = signupAndLogin("badstyle@newstory.test");

    Res res = post("/api/convert", Map.of("url", URL, "style", "poem"), tokens.accessToken());

    assertThat(res.status()).isEqualTo(400);
  }

  @Test
  void 본문을_못_뽑은_기사는_원문_조회가_502와_안내문구로_실패한다() {
    String empty = "https://news.example.com/article/empty";
    given(crawlingService.crawl(empty)).willThrow(new ArticleContentUnavailableException());

    Res res = get("/api/convert/original?url=" + empty, null);

    assertThat(res.status()).isEqualTo(502);
    assertThat((String) res.json("$.message")).contains("본문을 가져오지 못했어요");
  }

  @Test
  void 본문을_못_뽑은_기사는_변환도_AI를_부르지_않고_502() {
    String empty = "https://news.example.com/article/empty";
    given(crawlingService.crawl(empty)).willThrow(new ArticleContentUnavailableException());
    Tokens tokens = signupAndLogin("empty@newstory.test");

    Res res =
        post(
            "/api/convert",
            Map.of("url", empty, "style", "fairy_tale", "level", "MEDIUM"),
            tokens.accessToken());

    assertThat(res.status()).isEqualTo(502);
    verify(gemmaApiClient, never()).convert(anyString(), anyString(), anyString());
  }
}
