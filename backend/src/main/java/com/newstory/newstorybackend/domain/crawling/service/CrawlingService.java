package com.newstory.newstorybackend.domain.crawling.service;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.newstory.newstorybackend.domain.crawling.dto.CrawledArticle;
import com.newstory.newstorybackend.domain.crawling.exception.ArticleContentUnavailableException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class CrawlingService {

  private static final String USER_AGENT =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
          + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

  // tried in order — first candidate with sufficient clean paragraph text wins
  private static final List<String> CANDIDATE_SELECTORS =
      List.of(
          // very specific article body selectors first
          ".reporter_body",
          ".article_txt",
          "#article-view-content-div",
          ".story-news-article",
          ".article_body",
          ".detail-body",
          ".news_txt",
          ".content-body",
          ".newsct_article",
          "#newsct_article",
          ".article__body",
          ".view-article",
          ".article-content",
          // broader selectors last
          ".article-body",
          ".news_body",
          ".view_body",
          "article");

  private static final String NOISE_SELECTOR =
      "script, style, figure, figcaption, iframe, noscript, "
          + ".ad, .advertisement, .banner, .sponsor, "
          + ".related, .relation, .more-news, .recommend, "
          + ".share, .sns, .social, "
          + ".reporter-info, .reporter_profile, .byline, .author-info, "
          + "[class*='copyright'], [class*='license'], [class*='terms'], "
          + "[class*='tag'], [id*='tag'], "
          + "[class*='comment'], [id*='comment'], "
          + "[class*='ad'], [id*='ad']";

  private static final Pattern NOISE_TEXT =
      Pattern.compile(
          "(?i)(copyright|ⓒ|©|무단.?전재|재배포.?금지|저작권|구독하기|알림.?받기|"
              + "공유하기|SNS|카카오톡|페이스북|트위터|URL 복사|창 닫기|글자크기|"
              + "기자.?메일|\\[.*?기자\\]|광고문의|제보.?하기|"
              + "googletag|adsbygoogle|function\\s*\\(|window\\.|document\\.)");

  // minimum paragraph text length to consider a candidate usable
  private static final int MIN_CONTENT_LENGTH = 150;

  /** Arc XP(Fusion) 기반 사이트(조선일보 등)는 본문을 HTML이 아니라 이 스크립트 변수의 JSON에 담는다. */
  private static final String FUSION_MARKER = "Fusion.globalContent=";

  private static final ObjectMapper MAPPER = new ObjectMapper();

  public CrawledArticle crawl(String url) {
    try {
      Document doc =
          Jsoup.connect(url).userAgent(USER_AGENT).timeout(20_000).followRedirects(true).get();

      String title = doc.title();
      String content = extractContent(doc, url);
      if (content.isBlank()) {
        log.warn("본문 추출 실패 (빈 본문) url={}", url);
        throw new ArticleContentUnavailableException();
      }

      List<String> imageUrls =
          doc.select("img[src]").stream()
              .map(img -> img.absUrl("src"))
              .filter(src -> !src.isBlank())
              .limit(5)
              .toList();

      return new CrawledArticle(title, content, "", url, imageUrls);
    } catch (ArticleContentUnavailableException e) {
      throw e;
    } catch (Exception e) {
      log.error("크롤링 실패: {}", url, e);
      throw new RuntimeException("기사를 불러올 수 없습니다: " + url, e);
    }
  }

  String extractContent(Document doc, String url) {
    for (String selector : CANDIDATE_SELECTORS) {
      for (Element el : doc.select(selector)) {
        Optional<String> result = tryExtract(el, selector);
        if (result.isPresent()) {
          log.debug("크롤링 성공 selector={} url={}", selector, url);
          return result.get();
        }
      }
    }

    Optional<String> fusion = extractFusionContent(doc);
    if (fusion.isPresent()) {
      log.debug("크롤링 성공 (Fusion JSON) url={}", url);
      return fusion.get();
    }

    log.warn("모든 셀렉터 실패, body p 태그 fallback url={}", url);
    return fallbackExtract(doc);
  }

  /**
   * {@code Fusion.globalContent} JSON의 content_elements 중 type=text 문단을 순서대로 모은다. 문단 안의 HTML 태그는
   * 벗긴다.
   */
  Optional<String> extractFusionContent(Document doc) {
    for (Element script : doc.select("script")) {
      String data = script.data();
      int at = data.indexOf(FUSION_MARKER);
      if (at < 0) continue;
      try (JsonParser parser = MAPPER.createParser(data.substring(at + FUSION_MARKER.length()))) {
        JsonNode root = MAPPER.readTree(parser); // 첫 JSON 값만 읽고 뒤에 이어지는 스크립트는 무시
        List<String> paragraphs = new ArrayList<>();
        for (JsonNode el : root.path("content_elements")) {
          if (!"text".equals(el.path("type").asText())) continue;
          String text = Jsoup.parse(el.path("content").asText("")).text().trim();
          if (!text.isEmpty() && !NOISE_TEXT.matcher(text).find()) paragraphs.add(text);
        }
        if (!paragraphs.isEmpty()) return Optional.of(String.join("\n\n", paragraphs));
      } catch (Exception e) {
        log.debug("Fusion JSON 파싱 실패: {}", e.getMessage());
      }
    }
    return Optional.empty();
  }

  private Optional<String> tryExtract(Element el, String selector) {
    Element clone = el.clone();
    clone.select(NOISE_SELECTOR).remove();

    // try p tags first
    List<String> paragraphs =
        clone.select("p").stream()
            .map(Element::text)
            .map(String::trim)
            .filter(t -> t.length() >= 20)
            .filter(t -> !NOISE_TEXT.matcher(t).find())
            .toList();

    if (!paragraphs.isEmpty()) {
      String joined = String.join("\n\n", paragraphs);
      if (joined.length() >= MIN_CONTENT_LENGTH) {
        return Optional.of(joined);
      }
    }

    // p tags insufficient — use full element text, split into natural paragraphs
    String rawText = clone.text().trim();
    if (rawText.length() >= MIN_CONTENT_LENGTH) {
      String cleaned = splitIntoParagraphs(rawText);
      if (cleaned.length() >= MIN_CONTENT_LENGTH) {
        return Optional.of(cleaned);
      }
    }

    return Optional.empty();
  }

  private String splitIntoParagraphs(String raw) {
    // split on Korean sentence endings, group 3-4 sentences per paragraph
    String[] sentences = raw.split("(?<=[다요죠음]\\.) |(?<=[!?]\\.?) ");
    StringBuilder sb = new StringBuilder();
    int count = 0;
    for (String s : sentences) {
      String t = s.trim();
      if (t.length() < 15 || NOISE_TEXT.matcher(t).find()) continue;
      sb.append(t).append(" ");
      count++;
      if (count % 3 == 0) {
        // trim trailing space, add paragraph break
        int len = sb.length();
        if (len > 0 && sb.charAt(len - 1) == ' ') sb.deleteCharAt(len - 1);
        sb.append("\n\n");
      }
    }
    return sb.toString().trim();
  }

  private String fallbackExtract(Document doc) {
    List<String> lines =
        doc.body().select("p").stream()
            .map(Element::text)
            .map(String::trim)
            .filter(t -> t.length() >= 30)
            .filter(t -> !NOISE_TEXT.matcher(t).find())
            .toList();
    return String.join("\n\n", lines);
  }
}
