package com.newstory.newstorybackend.news;

import static org.assertj.core.api.Assertions.assertThat;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

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
}
