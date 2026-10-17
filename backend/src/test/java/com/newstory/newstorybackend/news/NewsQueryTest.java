package com.newstory.newstorybackend.news;

import static org.assertj.core.api.Assertions.assertThat;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.util.UriComponentsBuilder;

class NewsQueryTest extends IntegrationTestSupport {

  @Autowired NewsArticleRepository newsArticleRepository;

  @BeforeEach
  void seed() {
    save("https://a.example/1", "정치 기사", "정치", 1);
    save("https://a.example/2", "경제 기사", "경제", 2);
    save("https://a.example/3", "정치 기사 2", "정치", 3);
  }

  private void save(String url, String title, String category, int hoursAgo) {
    newsArticleRepository.save(
        NewsArticle.builder()
            .url(url)
            .title(title)
            .category(category)
            .source("테스트일보")
            .publishedAt(LocalDateTime.now().minusHours(hoursAgo))
            .build());
  }

  @Test
  void 카테고리로_필터하면_그_카테고리만_최신순으로_나온다() {
    Res res = get("/api/news?category=정치", null);

    assertThat(res.status()).isEqualTo(200);
    List<String> titles = res.json("$.data.content[*].title");
    assertThat(titles).containsExactly("정치 기사", "정치 기사 2");
  }

  @Test
  void 카테고리_목록은_DB에_있는_것만() {
    Res res = get("/api/news/categories", null);

    List<String> categories = res.json("$.data");
    assertThat(categories).containsExactlyInAnyOrder("정치", "경제");
  }

  @Test
  void 조회수_기록은_로그인_없이_된다() {
    Long id = newsArticleRepository.findByUrl("https://a.example/1").orElseThrow().getId();

    assertThat(post("/api/news/" + id + "/view", null, null).status()).isEqualTo(200);
  }

  // ───────────── 제목 검색 (16번) ─────────────

  /** 검색어의 %, _ 같은 문자를 그대로 보내려고 직접 인코딩한 URI로 요청한다. */
  private Res search(String keyword, String category) {
    UriComponentsBuilder b = UriComponentsBuilder.fromPath("/api/news");
    if (keyword != null) b.queryParam("keyword", keyword);
    if (category != null) b.queryParam("category", category);
    return getEncoded(b.encode(StandardCharsets.UTF_8).build().toUriString());
  }

  private List<String> titles(Res res) {
    assertThat(res.status()).isEqualTo(200);
    return res.json("$.data.content[*].title");
  }

  @Test
  void 제목_일부로_검색하면_포함된_기사만_최신순() {
    assertThat(titles(search("정치", null))).containsExactly("정치 기사", "정치 기사 2");
    assertThat(titles(search("기사 2", null))).containsExactly("정치 기사 2");
  }

  @Test
  void 영문은_대소문자_무시() {
    save("https://a.example/4", "OpenAI 새 모델 공개", "IT", 0);

    assertThat(titles(search("openai", null))).containsExactly("OpenAI 새 모델 공개");
    assertThat(titles(search("OPENAI", null))).containsExactly("OpenAI 새 모델 공개");
  }

  @Test
  void 검색어와_카테고리를_같이_쓰면_둘_다_맞는_것만() {
    save("https://a.example/5", "정치권 경제 공방", "경제", 0);

    assertThat(titles(search("정치", "경제"))).containsExactly("정치권 경제 공방");
    assertThat(titles(search("정치", "정치"))).containsExactly("정치 기사", "정치 기사 2");
  }

  @Test
  void 퍼센트와_밑줄은_와일드카드가_아니라_글자_그대로_찾는다() {
    save("https://a.example/6", "금리 3% 인상", "경제", 0);
    save("https://a.example/7", "snake_case 표기", "IT", 0);

    assertThat(titles(search("%", null))).containsExactly("금리 3% 인상");
    assertThat(titles(search("_", null))).containsExactly("snake_case 표기");
    assertThat(titles(search("3%", null))).containsExactly("금리 3% 인상");
  }

  @Test
  void 공백만_있는_검색어는_전체_목록과_같다() {
    assertThat(titles(search("   ", null))).containsExactly("정치 기사", "경제 기사", "정치 기사 2");
  }

  @Test
  void 결과가_없으면_빈_목록() {
    assertThat(titles(search("없는단어", null))).isEmpty();
  }

  @Test
  void 검색어가_50자를_넘으면_400() {
    assertThat(search("가".repeat(51), null).status()).isEqualTo(400);
    assertThat(search("가".repeat(50), null).status()).isEqualTo(200);
  }
}
