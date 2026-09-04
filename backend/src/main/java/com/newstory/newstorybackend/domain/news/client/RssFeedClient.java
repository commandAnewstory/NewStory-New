package com.newstory.newstorybackend.domain.news.client;

import com.newstory.newstorybackend.domain.news.dto.RssItem;
import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.parser.Parser;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class RssFeedClient {

  private static final DateTimeFormatter RFC_822 =
      DateTimeFormatter.ofPattern("EEE, dd MMM yyyy HH:mm:ss z", Locale.ENGLISH);

  public List<RssItem> fetch(String url, String sourceName, String category, String sourceType) {
    List<RssItem> items = new ArrayList<>();
    try {
      Document doc =
          Jsoup.connect(url)
              .userAgent("Mozilla/5.0 NewStory RSS Collector")
              .timeout(10_000)
              .parser(Parser.xmlParser())
              .get();

      for (Element item : doc.select("item")) {
        String title = text(item, "title");
        String link = text(item, "link");
        if (title.isBlank() || link.isBlank()) continue;

        String description = text(item, "description");
        if (description.isBlank()) description = text(item, "content:encoded");

        LocalDateTime publishedAt = parseDate(text(item, "pubDate"));

        items.add(
            RssItem.builder()
                .title(title)
                .link(link)
                .description(description)
                .source(sourceName)
                .category(category)
                .sourceType(sourceType)
                .publishedAt(publishedAt)
                .build());
      }
    } catch (Exception e) {
      log.warn("RSS 수집 실패 [{}]: {}", url, e.getMessage());
    }
    return items;
  }

  private String text(Element parent, String tag) {
    Element el = parent.selectFirst(tag);
    return el == null ? "" : el.text().trim();
  }

  private LocalDateTime parseDate(String raw) {
    if (raw == null || raw.isBlank()) return LocalDateTime.now();
    try {
      return ZonedDateTime.parse(raw.trim(), RFC_822).toLocalDateTime();
    } catch (DateTimeParseException e) {
      log.debug("pubDate 파싱 실패, 현재시각 사용: {}", raw);
      return LocalDateTime.now();
    }
  }
}
