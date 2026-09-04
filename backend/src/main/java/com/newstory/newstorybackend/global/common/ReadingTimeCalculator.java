package com.newstory.newstorybackend.global.common;

public final class ReadingTimeCalculator {

  private static final int CHARS_PER_MINUTE = 500;

  private ReadingTimeCalculator() {}

  public static String calculate(String text) {
    if (text == null || text.isBlank()) {
      return "약 30초";
    }
    int length = text.replaceAll("\\s+", "").length();
    if (length <= 250) {
      return "약 30초";
    }
    int minutes = (int) Math.ceil((double) length / CHARS_PER_MINUTE);
    return "약 " + minutes + "분";
  }
}
