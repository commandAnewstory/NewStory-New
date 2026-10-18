package com.newstory.newstorybackend.global.common;

import org.jsoup.Jsoup;

/** RSS 설명처럼 HTML 조각(이스케이프된 `&lt;img ...&gt;` 포함)이 섞인 문자열을 화면용 순수 텍스트로. */
public final class HtmlText {

  private HtmlText() {}

  public static String plain(String raw) {
    if (raw == null || raw.isBlank()) return raw;
    // RSS의 description은 HTML이 한 번 이스케이프된 채 텍스트로 들어오는 경우가 많아서 두 번 벗긴다
    String once = Jsoup.parse(raw).text();
    String twice = once.contains("<") ? Jsoup.parse(once).text() : once;
    return twice.replaceAll("\\s+", " ").trim();
  }
}
