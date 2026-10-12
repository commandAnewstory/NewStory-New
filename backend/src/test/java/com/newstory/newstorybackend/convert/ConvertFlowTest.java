package com.newstory.newstorybackend.convert;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;

import com.newstory.newstorybackend.domain.ai.dto.VerificationResult;
import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
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
}
