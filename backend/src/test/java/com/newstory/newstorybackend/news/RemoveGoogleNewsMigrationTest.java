package com.newstory.newstorybackend.news;

import static org.assertj.core.api.Assertions.assertThat;

import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;

/** V9 마이그레이션 SQL을 시드 데이터에 다시 실행해서 무엇을 지우고 무엇을 남기는지 확인 */
class RemoveGoogleNewsMigrationTest extends IntegrationTestSupport {

  @Autowired JdbcTemplate jdbc;

  private long article(String url, String sourceType) {
    return jdbc.queryForObject(
        "insert into news_articles (url, title, source, category, source_type) values (?, ?, ?, '정치', ?) returning id",
        Long.class,
        url,
        "기사 " + url,
        sourceType.equals("rss") ? "동아일보" : "Google News",
        sourceType);
  }

  @Test
  void 구글뉴스_기사는_조회기록까지_지우고_변환캐시가_있거나_일반_RSS면_남긴다() throws Exception {
    long rss = article("https://donga.example/1", "rss");
    long google = article("https://news.google.com/rss/articles/a", "google_news");
    long googleViewed = article("https://news.google.com/rss/articles/b", "google_news");
    long googleCached = article("https://news.google.com/rss/articles/c", "google_news");
    jdbc.update("insert into article_views (article_id) values (?)", googleViewed);
    jdbc.update("insert into article_views (article_id) values (?)", rss);
    jdbc.update(
        "insert into conversion_cache (article_id, style, converted_text) values (?, 'card', '요약')",
        googleCached);

    String sql =
        new ClassPathResource("db/migration/V9__remove_google_news_articles.sql")
            .getContentAsString(StandardCharsets.UTF_8);
    for (String stmt : sql.replaceAll("(?m)^--.*$", "").split(";")) {
      if (!stmt.isBlank()) jdbc.execute(stmt);
    }

    List<Long> left = jdbc.queryForList("select id from news_articles order by id", Long.class);
    assertThat(left).containsExactly(rss, googleCached);
    assertThat(jdbc.queryForObject("select count(*) from article_views", Long.class)).isEqualTo(1);
    assertThat(google).isNotIn(left);
  }
}
