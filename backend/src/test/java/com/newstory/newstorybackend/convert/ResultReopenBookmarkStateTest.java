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

class ResultReopenBookmarkStateTest extends IntegrationTestSupport {

  static final String URL_A = "https://news.example.com/a";
  static final String URL_B = "https://news.example.com/b";

  String token;

  @BeforeEach
  void setUp() {
    for (String url : List.of(URL_A, URL_B)) {
      given(crawlingService.crawl(url))
          .willReturn(new CrawledArticle("기사 " + url, "원문", "<p>원문</p>", url, List.of()));
    }
    given(gemmaApiClient.convert(anyString(), anyString(), anyString()))
        .willReturn("- 오늘 {{term:기준금리|한국은행이 정하는 기본 금리}}가 올랐다\n- 둘째 줄");
    given(claudeApiClient.verify(anyString(), anyString())).willReturn(VerificationResult.passed());
    token = signupAndLogin("reopen@newstory.test").accessToken();
  }

  private Res convert(String url, String style, String level, String withToken) {
    return post("/api/convert", Map.of("url", url, "style", style, "level", level), withToken);
  }

  private int resultRows() {
    return jdbcTemplate.queryForObject("select count(*) from converted_results", Integer.class);
  }

  @Test
  void 같은_기사_스타일_레벨을_다시_열면_같은_결과를_재사용한다() {
    int first = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");
    int second = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");

    assertThat(second).isEqualTo(first);
    assertThat(resultRows()).isEqualTo(1);
  }

  @Test
  void 레벨이나_스타일이_다르면_별도_결과() {
    int medium = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");
    int low = convert(URL_A, "novel", "LOW", token).json("$.data.id");
    int card = convert(URL_A, "card", "MEDIUM", token).json("$.data.id");

    assertThat(List.of(medium, low, card)).doesNotHaveDuplicates();
  }

  @Test
  void 다른_사용자는_같은_기사여도_자기_결과를_따로_가진다() {
    String other = signupAndLogin("other-reopen@newstory.test").accessToken();

    int mine = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");
    int theirs = convert(URL_A, "novel", "MEDIUM", other).json("$.data.id");

    assertThat(theirs).isNotEqualTo(mine);
    assertThat(jdbcTemplate.queryForObject("select count(*) from conversion_cache", Integer.class))
        .isEqualTo(1);
  }

  @Test
  void 보관함_저장_여부가_변환_응답에_들어간다() {
    Res before = convert(URL_A, "novel", "MEDIUM", token);
    int id = before.json("$.data.id");
    assertThat((Boolean) before.json("$.data.bookmarked")).isFalse();

    post("/api/bookmarks/" + id, null, token);
    Res after = convert(URL_A, "novel", "MEDIUM", token);
    assertThat((Integer) after.json("$.data.id")).isEqualTo(id);
    assertThat((Boolean) after.json("$.data.bookmarked")).isTrue();

    delete("/api/bookmarks/" + id, token);
    assertThat((Boolean) convert(URL_A, "novel", "MEDIUM", token).json("$.data.bookmarked"))
        .isFalse();
  }

  @Test
  void 결과_단건_조회에_용어풀이_읽기시간_저장여부가_들어간다() {
    int id = convert(URL_A, "card", "HIGH", token).json("$.data.id");
    post("/api/bookmarks/" + id, null, token);

    Res res = get("/api/convert/" + id, token);

    assertThat(res.status()).isEqualTo(200);
    assertThat((String) res.json("$.data.glossary[0].term")).isEqualTo("기준금리");
    assertThat((String) res.json("$.data.glossary[0].definition")).isEqualTo("한국은행이 정하는 기본 금리");
    assertThat((String) res.json("$.data.readingTimeLabel")).isNotBlank();
    assertThat((String) res.json("$.data.level")).isEqualTo("HIGH");
    assertThat((Boolean) res.json("$.data.bookmarked")).isTrue();
  }

  @Test
  void 남의_결과는_조회할_수_없다() {
    int id = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");
    String other = signupAndLogin("intruder@newstory.test").accessToken();

    assertThat(get("/api/convert/" + id, other).status()).isEqualTo(401);
  }

  @Test
  void 히스토리는_마지막으로_본_순서이고_중복이_없다() {
    convert(URL_A, "novel", "MEDIUM", token);
    convert(URL_B, "novel", "MEDIUM", token);
    convert(URL_A, "novel", "MEDIUM", token);

    Res history = get("/api/history", token);
    List<String> urls = history.json("$.data[*].articleUrl");
    assertThat(urls).containsExactly(URL_A, URL_B);
    assertThat((String) history.json("$.data[0].level")).isEqualTo("MEDIUM");
  }

  @Test
  void 보관함에_있는_항목을_히스토리에서_지우면_히스토리에서만_빠진다() {
    int id = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");
    post("/api/bookmarks/" + id, null, token);

    assertThat(delete("/api/history/" + id, token).status()).isEqualTo(200);

    assertThat((List<?>) get("/api/history", token).json("$.data")).isEmpty();
    Res bookmarks = get("/api/bookmarks", token);
    assertThat((Integer) bookmarks.json("$.data[0].resultId")).isEqualTo(id);
    assertThat((String) bookmarks.json("$.data[0].articleUrl")).isEqualTo(URL_A);
    assertThat(get("/api/convert/" + id, token).status()).isEqualTo(200);

    int again = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");
    assertThat(again).isEqualTo(id);
    assertThat((Integer) get("/api/history", token).json("$.data[0].resultId")).isEqualTo(id);
  }

  @Test
  void 보관함에_없는_항목은_히스토리에서_지우면_실제로_삭제된다() {
    int id = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");

    assertThat(delete("/api/history/" + id, token).status()).isEqualTo(200);

    assertThat(resultRows()).isZero();
    assertThat(get("/api/convert/" + id, token).status()).isEqualTo(404);
  }

  @Test
  void 예전에_쌓인_중복_행이_있으면_보관함에_든_행을_재사용한다() {
    int bookmarkedId = convert(URL_A, "novel", "MEDIUM", token).json("$.data.id");
    post("/api/bookmarks/" + bookmarkedId, null, token);
    // V7 이전처럼 같은 키의 행이 하나 더 있고, 그게 더 최근에 본 행인 상황
    jdbcTemplate.update(
        "insert into converted_results (article_id, user_id, style, level, converted_text,"
            + " verification_passed, retry_count, is_feed, created_at, viewed_at)"
            + " select article_id, user_id, style, level, converted_text, verification_passed,"
            + " retry_count, is_feed, now(), now() + interval '1 hour'"
            + " from converted_results where id = ?",
        bookmarkedId);

    Res again = convert(URL_A, "novel", "MEDIUM", token);

    assertThat((Integer) again.json("$.data.id")).isEqualTo(bookmarkedId);
    assertThat((Boolean) again.json("$.data.bookmarked")).isTrue();
  }
}
