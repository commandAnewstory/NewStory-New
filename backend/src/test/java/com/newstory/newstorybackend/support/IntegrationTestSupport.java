package com.newstory.newstorybackend.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.jayway.jsonpath.JsonPath;
import com.newstory.newstorybackend.domain.ai.client.ClaudeApiClient;
import com.newstory.newstorybackend.domain.ai.client.GemmaApiClient;
import com.newstory.newstorybackend.domain.crawling.service.CrawlingService;
import com.newstory.newstorybackend.domain.news.service.ArticleCleanupService;
import com.newstory.newstorybackend.domain.news.service.RssNewsCollector;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.web.client.RestClient;

/**
 * 통합 테스트 공통 기반.
 *
 * <ul>
 *   <li>실제 HTTP 요청으로 컨트롤러~DB까지 전부 태운다 (RANDOM_PORT)
 *   <li>DB는 이름이 {@code _test} 로 끝나는 전용 DB만 사용한다. 아니면 테스트를 즉시 실패시킨다
 *   <li>외부 호출(Gemma, Claude, 언론사 크롤링, RSS 수집, 기사 정리 스케줄러)은 전부 가짜로 대체한다
 * </ul>
 *
 * <p>로컬 실행: {@code createdb newstory_test} 한 번 만든 뒤 {@code ./gradlew test}. 접속 정보는 환경변수 {@code
 * TEST_DB_URL}, {@code TEST_DB_USERNAME}, {@code TEST_DB_PASSWORD} 로 바꿀 수 있다.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public abstract class IntegrationTestSupport {

  private static final String DEFAULT_DB_URL = "jdbc:postgresql://localhost:5432/newstory_test";

  @DynamicPropertySource
  static void testProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", () -> env("TEST_DB_URL", DEFAULT_DB_URL));
    registry.add(
        "spring.datasource.username",
        () -> env("TEST_DB_USERNAME", System.getProperty("user.name")));
    registry.add("spring.datasource.password", () -> env("TEST_DB_PASSWORD", ""));
    registry.add("jwt.secret", () -> "integration-test-jwt-secret-at-least-32-bytes!!");
    registry.add("claude.api-key", () -> "test-key-not-used");
    registry.add("gemma.api-url", () -> "http://127.0.0.1:1/not-used");
  }

  private static String env(String key, String fallback) {
    String value = System.getenv(key);
    return (value == null || value.isBlank()) ? fallback : value;
  }

  @MockitoBean protected GemmaApiClient gemmaApiClient;
  @MockitoBean protected ClaudeApiClient claudeApiClient;
  @MockitoBean protected CrawlingService crawlingService;
  @MockitoBean protected RssNewsCollector rssNewsCollector;
  @MockitoBean protected ArticleCleanupService articleCleanupService;

  @Autowired protected JdbcTemplate jdbcTemplate;

  @LocalServerPort private int port;

  protected RestClient http;

  @BeforeEach
  void resetDatabaseAndClient() {
    String database = jdbcTemplate.queryForObject("select current_database()", String.class);
    assertThat(database).as("테스트는 이름이 _test 로 끝나는 DB에서만 돌린다 (개발 DB 보호)").endsWith("_test");

    List<String> tables =
        jdbcTemplate.queryForList(
            "select tablename from pg_tables where schemaname = 'public'"
                + " and tablename <> 'flyway_schema_history'",
            String.class);
    if (!tables.isEmpty()) {
      jdbcTemplate.execute(
          "truncate table " + String.join(", ", tables) + " restart identity cascade");
    }

    http = RestClient.builder().baseUrl("http://localhost:" + port).build();
  }

  // ───────────── HTTP helpers ─────────────

  protected record Res(int status, String body) {
    public <T> T json(String path) {
      return JsonPath.read(body, path);
    }
  }

  protected Res get(String path, String token) {
    return send(HttpMethod.GET, path, null, token);
  }

  protected Res post(String path, Object body, String token) {
    return send(HttpMethod.POST, path, body, token);
  }

  protected Res patch(String path, Object body, String token) {
    return send(HttpMethod.PATCH, path, body, token);
  }

  protected Res delete(String path, String token) {
    return send(HttpMethod.DELETE, path, null, token);
  }

  protected Res send(HttpMethod method, String path, Object body, String token) {
    RestClient.RequestBodySpec spec = http.method(method).uri(path);
    if (token != null) {
      spec.header(HttpHeaders.AUTHORIZATION, "Bearer " + token);
    }
    if (body != null) {
      spec.contentType(MediaType.APPLICATION_JSON).body(body);
    }
    return spec.exchange(
        (request, response) ->
            new Res(
                response.getStatusCode().value(),
                new String(response.getBody().readAllBytes(), StandardCharsets.UTF_8)));
  }

  // ───────────── domain helpers ─────────────

  protected record Tokens(String accessToken, String refreshToken) {}

  protected Tokens signupAndLogin(String email) {
    Res signup =
        post(
            "/api/auth/signup",
            Map.of("email", email, "password", "password1234", "nickname", "tester"),
            null);
    assertThat(signup.status()).isEqualTo(201);

    Res login = post("/api/auth/login", Map.of("email", email, "password", "password1234"), null);
    assertThat(login.status()).isEqualTo(200);
    return new Tokens(login.json("$.data.accessToken"), login.json("$.data.refreshToken"));
  }
}
