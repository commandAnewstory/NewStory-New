package com.newstory.newstorybackend.bookmark;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;

import com.newstory.newstorybackend.domain.ai.dto.VerificationResult;
import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class BookmarkHistoryFlowTest extends IntegrationTestSupport {

  static final String URL = "https://news.example.com/article/2";

  @Autowired NewsArticleRepository newsArticleRepository;

  Tokens tokens;
  int resultId;

  @BeforeEach
  void convertOnce() {
    given(crawlingService.crawl(URL))
        .willReturn(new CrawledArticle("보관함 테스트 기사", "원문", "<p>원문</p>", URL, List.of()));
    given(gemmaApiClient.convert(anyString(), anyString(), anyString())).willReturn("옛날 옛적에");
    given(claudeApiClient.verify(anyString(), anyString())).willReturn(VerificationResult.passed());

    tokens = signupAndLogin("bookmark@newstory.test");
    Res res = post("/api/convert", Map.of("url", URL, "style", "fairy_tale"), tokens.accessToken());
    assertThat(res.status()).isEqualTo(200);
    resultId = res.json("$.data.id");
  }

  @Test
  void 보관함_추가_중복추가_조회_삭제() {
    String token = tokens.accessToken();

    assertThat(post("/api/bookmarks/" + resultId, null, token).status()).isEqualTo(201);
    assertThat(post("/api/bookmarks/" + resultId, null, token).status()).isEqualTo(409);

    Res list = get("/api/bookmarks", token);
    assertThat(list.status()).isEqualTo(200);
    assertThat((Integer) list.json("$.data[0].resultId")).isEqualTo(resultId);
    assertThat((String) list.json("$.data[0].articleTitle")).isEqualTo("보관함 테스트 기사");

    assertThat(delete("/api/bookmarks/" + resultId, token).status()).isEqualTo(200);
    assertThat((List<?>) get("/api/bookmarks", token).json("$.data")).isEmpty();
  }

  @Test
  void 히스토리_조회_삭제() {
    String token = tokens.accessToken();

    Res history = get("/api/history", token);
    assertThat(history.status()).isEqualTo(200);
    assertThat((Integer) history.json("$.data[0].resultId")).isEqualTo(resultId);
    assertThat((String) history.json("$.data[0].style")).isEqualTo("fairy_tale");

    assertThat(delete("/api/history/" + resultId, token).status()).isEqualTo(200);
    assertThat((List<?>) get("/api/history", token).json("$.data")).isEmpty();
  }

  @Test
  void 다른_사용자의_보관함은_보이지_않는다() {
    post("/api/bookmarks/" + resultId, null, tokens.accessToken());

    Tokens other = signupAndLogin("other@newstory.test");

    assertThat((List<?>) get("/api/bookmarks", other.accessToken()).json("$.data")).isEmpty();
    assertThat(delete("/api/bookmarks/" + resultId, other.accessToken()).status()).isEqualTo(404);
  }

  @Test
  void 보관함과_히스토리에_기사_카테고리가_나온다_직접_변환한_기사는_null() {
    String rssUrl = "https://news.example.com/article/rss";
    newsArticleRepository.save(
        NewsArticle.builder().url(rssUrl).title("RSS 경제 기사").category("경제").build());
    given(crawlingService.crawl(rssUrl))
        .willReturn(new CrawledArticle("RSS 경제 기사", "원문", "<p>원문</p>", rssUrl, List.of()));
    String token = tokens.accessToken();
    int rssResultId =
        post("/api/convert", Map.of("url", rssUrl, "style", "card"), token).json("$.data.id");
    post("/api/bookmarks/" + rssResultId, null, token);

    Res history = get("/api/history", token);
    assertThat((String) history.json("$.data[0].category")).isEqualTo("경제");
    assertThat((Object) history.json("$.data[1].category")).isNull(); // 직접 변환(URL로만 들어온) 기사
    assertThat((String) get("/api/bookmarks", token).json("$.data[0].category")).isEqualTo("경제");
  }
}
