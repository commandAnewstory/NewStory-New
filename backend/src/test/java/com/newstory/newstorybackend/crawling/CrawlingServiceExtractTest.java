package com.newstory.newstorybackend.crawling;

import static org.assertj.core.api.Assertions.assertThat;

import com.newstory.newstorybackend.domain.crawling.service.CrawlingServiceTestAccess;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.junit.jupiter.api.Test;

/** 네트워크 없이 HTML 구조별 본문 추출만 검증한다. */
class CrawlingServiceExtractTest {

  private final CrawlingServiceTestAccess crawler = new CrawlingServiceTestAccess();

  private static final String P1 = "첫 번째 문단입니다. 사실은 바꾸지 않고 형식만 바꾸는 테스트용 본문 문장입니다.";
  private static final String P2 =
      "두 번째 문단에는 <b>굵은 글씨</b>와 <a href=\\\"https://x\\\">링크</a>가 섞여 있습니다.";
  private static final String P3 = "세 번째 문단입니다. 길이를 맞추기 위해 조금 더 긴 문장을 붙여 둡니다.";

  /** 조선일보(Arc XP) 형태: 본문 HTML엔 p가 없고 스크립트 JSON에만 문단이 있다. */
  private static Document fusionPage() {
    String json =
        "{\"headlines\":{\"basic\":\"제목\"},\"content_elements\":["
            + "{\"type\":\"image\",\"url\":\"https://img\"},"
            + "{\"type\":\"text\",\"content\":\""
            + P1
            + "\"},"
            + "{\"type\":\"text\",\"content\":\""
            + P2
            + "\"},"
            + "{\"type\":\"text\",\"content\":\"\"},"
            + "{\"type\":\"text\",\"content\":\""
            + P3
            + "\"}]}";
    return Jsoup.parse(
        "<html><head><title>t</title></head><body><div id=\"fusion-app\"></div>"
            + "<script>window.x=1;Fusion=window.Fusion||{};Fusion.globalContent="
            + json
            + ";Fusion.globalContentConfig={\"a\":1};</script></body></html>");
  }

  @Test
  void Fusion_JSON에서_text_문단만_순서대로_태그_벗겨서_뽑는다() {
    String content = crawler.extractContent(fusionPage());

    assertThat(content.split("\n\n")).containsExactly(P1, "두 번째 문단에는 굵은 글씨와 링크가 섞여 있습니다.", P3);
  }

  @Test
  void 일반_HTML_기사는_기존처럼_셀렉터로_뽑는다() {
    String body = "<p>" + P1 + "</p><p>" + P3 + "</p><p>" + P1 + "</p>";
    Document doc =
        Jsoup.parse("<html><body><div class=\"article_body\">" + body + "</div></body></html>");

    assertThat(crawler.extractContent(doc)).startsWith(P1).contains(P3);
  }

  @Test
  void 본문이_어디에도_없으면_빈_문자열() {
    Document doc =
        Jsoup.parse("<html><body><div id=\"app\"></div><script>var a=1;</script></body></html>");

    assertThat(crawler.extractContent(doc)).isEmpty();
  }

  @Test
  void Fusion_JSON이_깨져_있어도_예외_없이_넘어간다() {
    Document doc =
        Jsoup.parse(
            "<html><body><script>Fusion.globalContent={\"content_elements\":[{\"type\":</script>"
                + "</body></html>");

    assertThat(crawler.extractContent(doc)).isEmpty();
  }
}
