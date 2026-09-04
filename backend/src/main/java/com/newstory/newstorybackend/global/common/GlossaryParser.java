package com.newstory.newstorybackend.global.common;

import com.newstory.newstorybackend.domain.convert.dto.GlossaryItem;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class GlossaryParser {

  private static final Pattern MARKER = Pattern.compile("\\{\\{term:([^|]+)\\|([^}]+)}}");

  private GlossaryParser() {}

  public static ParsedContent parse(String text) {
    if (text == null || text.isBlank()) {
      return new ParsedContent(text == null ? "" : text, List.of());
    }

    List<GlossaryItem> glossary = new ArrayList<>();
    Matcher matcher = MARKER.matcher(text);
    StringBuffer sb = new StringBuffer();

    while (matcher.find()) {
      String term = matcher.group(1).trim();
      String definition = matcher.group(2).trim();
      glossary.add(new GlossaryItem(term, definition));
      matcher.appendReplacement(sb, Matcher.quoteReplacement(term));
    }
    matcher.appendTail(sb);

    return new ParsedContent(sb.toString(), List.copyOf(glossary));
  }

  public record ParsedContent(String plainText, List<GlossaryItem> glossary) {}
}
