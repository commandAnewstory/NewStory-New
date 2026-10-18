package com.newstory.newstorybackend.widget;

import static org.assertj.core.api.Assertions.assertThat;

import com.newstory.newstorybackend.domain.news.entity.ArticleView;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.ArticleViewRepository;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.util.UriComponentsBuilder;

class InterestPopularWidgetTest extends IntegrationTestSupport {

  @Autowired NewsArticleRepository newsArticleRepository;
  @Autowired ArticleViewRepository articleViewRepository;

  private static final LocalDateTime TODAY = LocalDate.now().atStartOfDay();

  private NewsArticle article(String title, String category, LocalDateTime publishedAt) {
    return newsArticleRepository.save(
        NewsArticle.builder()
            .url("https://a.example/" + title)
            .title(title)
            .category(category)
            .source("테스트일보")
            .publishedAt(publishedAt)
            .build());
  }

  private void views(NewsArticle a, int count, LocalDateTime at) {
    for (int i = 0; i < count; i++) {
      articleViewRepository.save(ArticleView.builder().article(a).viewedAt(at).build());
    }
  }

  private List<String> popular(String categories) {
    UriComponentsBuilder b = UriComponentsBuilder.fromPath("/api/widget/popular");
    if (categories != null) b.queryParam("categories", categories);
    Res res = getEncoded(b.encode(StandardCharsets.UTF_8).build().toUriString());
    assertThat(res.status()).isEqualTo(200);
    return res.json("$.data[*].title");
  }

  // ───────────── 관심 카테고리 저장 ─────────────

  @Test
  void 관심_카테고리를_저장하면_내_정보에_그대로_나온다() {
    Tokens t = signupAndLogin("interest@newstory.test");

    Res res =
        patch(
            "/api/users/me",
            Map.of("interestCategories", List.of("IT", "정치", "IT")),
            t.accessToken());

    assertThat(res.status()).isEqualTo(200);
    List<String> saved = get("/api/users/me", t.accessToken()).json("$.data.interestCategories");
    assertThat(saved).containsExactly("IT", "정치");
  }

  @Test
  void 처음엔_빈_목록이고_빈_배열로_보내면_전체로_초기화() {
    Tokens t = signupAndLogin("interest2@newstory.test");
    List<String> initial = get("/api/users/me", t.accessToken()).json("$.data.interestCategories");
    assertThat(initial).isEmpty();

    patch("/api/users/me", Map.of("interestCategories", List.of("경제")), t.accessToken());
    patch("/api/users/me", Map.of("interestCategories", List.of()), t.accessToken());

    List<String> saved = get("/api/users/me", t.accessToken()).json("$.data.interestCategories");
    assertThat(saved).isEmpty();
  }

  @Test
  void 지원하지_않는_카테고리는_400이고_저장도_안_된다() {
    Tokens t = signupAndLogin("interest3@newstory.test");
    patch("/api/users/me", Map.of("interestCategories", List.of("정치")), t.accessToken());

    Res res =
        patch("/api/users/me", Map.of("interestCategories", List.of("정치", "국제")), t.accessToken());

    assertThat(res.status()).isEqualTo(400);
    List<String> saved = get("/api/users/me", t.accessToken()).json("$.data.interestCategories");
    assertThat(saved).containsExactly("정치");
  }

  @Test
  void 다른_필드만_바꾸면_관심_카테고리는_그대로() {
    Tokens t = signupAndLogin("interest4@newstory.test");
    patch("/api/users/me", Map.of("interestCategories", List.of("스포츠")), t.accessToken());

    patch("/api/users/me", Map.of("widgetEnabled", true), t.accessToken());

    List<String> saved = get("/api/users/me", t.accessToken()).json("$.data.interestCategories");
    assertThat(saved).containsExactly("스포츠");
  }

  // ───────────── 관심 인기 뉴스 ─────────────

  @Test
  void 오늘_기사_중_오늘_조회수_많은_순_동률이면_최신순() {
    NewsArticle a = article("정치A", "정치", TODAY.plusMinutes(10));
    NewsArticle b = article("정치B", "정치", TODAY.plusMinutes(20));
    NewsArticle c = article("정치C", "정치", TODAY.plusMinutes(30));
    NewsArticle d = article("정치D", "정치", TODAY.plusMinutes(40));
    views(a, 5, TODAY.plusMinutes(50));
    views(c, 2, TODAY.plusMinutes(50));
    views(b, 2, TODAY.plusMinutes(50));
    views(d, 9, TODAY.minusDays(1)); // 어제 조회는 안 셈

    assertThat(popular("정치")).containsExactly("정치A", "정치C", "정치B");
  }

  @Test
  void 어제_기사는_조회가_많아도_오늘_기사보다_뒤_모자라면_최신으로_채운다() {
    NewsArticle old = article("어제 인기", "IT", TODAY.minusHours(3));
    views(old, 20, TODAY.plusMinutes(5));
    article("오늘 IT", "IT", TODAY.plusMinutes(5));
    article("그제 IT", "IT", TODAY.minusDays(2));

    assertThat(popular("IT")).containsExactly("오늘 IT", "어제 인기", "그제 IT");
  }

  @Test
  void 여러_관심_카테고리_중에서만_고른다() {
    article("정치1", "정치", TODAY.plusMinutes(1));
    article("경제1", "경제", TODAY.plusMinutes(2));
    article("스포츠1", "스포츠", TODAY.plusMinutes(3));

    assertThat(popular("정치,경제")).containsExactlyInAnyOrder("정치1", "경제1");
  }

  @Test
  void 카테고리를_안_주거나_엉뚱한_값만_주면_전체() {
    article("정치1", "정치", TODAY.plusMinutes(1));
    article("조선 전체", "전체", TODAY.plusMinutes(2));
    article("스포츠1", "스포츠", TODAY.plusMinutes(3));

    assertThat(popular(null)).containsExactly("스포츠1", "조선 전체", "정치1");
    assertThat(popular("국제,없는거")).containsExactly("스포츠1", "조선 전체", "정치1");
  }

  @Test
  void 최대_3개에_중복_없음() {
    for (int i = 0; i < 5; i++) {
      NewsArticle a = article("경제" + i, "경제", TODAY.plusMinutes(i));
      views(a, i, TODAY.plusMinutes(30));
    }

    List<String> titles = popular("경제");
    assertThat(titles).hasSize(3).doesNotHaveDuplicates().containsExactly("경제4", "경제3", "경제2");
  }

  @Test
  void 응답엔_기사_id와_카테고리가_있고_로그인_없이_된다() {
    NewsArticle a = article("정치1", "정치", TODAY.plusMinutes(1));

    Res res = get("/api/widget/popular", null);

    assertThat(res.status()).isEqualTo(200);
    assertThat(((Number) res.json("$.data[0].articleId")).longValue()).isEqualTo(a.getId());
    assertThat((String) res.json("$.data[0].category")).isEqualTo("정치");
  }
}
