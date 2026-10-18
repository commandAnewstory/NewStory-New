package com.newstory.newstorybackend.domain.user.entity;

import java.util.Arrays;
import java.util.List;

/** 관심 카테고리 허용값. 앱 카테고리 칩(국제 제외)과 같은 목록이어야 한다. */
public final class InterestCategories {

  public static final List<String> ALLOWED = List.of("정치", "경제", "사회", "문화", "IT", "스포츠");

  private InterestCategories() {}

  /** 쉼표 구분 문자열 → 허용값만, 순서 유지, 중복 제거. 비어 있으면 빈 목록(= 전체). */
  public static List<String> parse(String csv) {
    if (csv == null || csv.isBlank()) return List.of();
    return Arrays.stream(csv.split(","))
        .map(String::trim)
        .filter(ALLOWED::contains)
        .distinct()
        .toList();
  }

  public static String join(List<String> categories) {
    return String.join(",", categories);
  }
}
