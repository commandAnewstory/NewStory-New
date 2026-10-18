package com.newstory.newstorybackend.domain.widget.controller;

import com.newstory.newstorybackend.domain.widget.dto.PopularNewsResponse;
import com.newstory.newstorybackend.domain.widget.dto.TodayCardResponse;
import com.newstory.newstorybackend.domain.widget.service.WidgetService;
import com.newstory.newstorybackend.global.common.ApiResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/widget")
@RequiredArgsConstructor
public class WidgetController {

  private final WidgetService widgetService;

  @GetMapping("/today-cards")
  public ApiResponse<List<TodayCardResponse>> getTodayCards() {
    return ApiResponse.ok(widgetService.getTodayCards());
  }

  /** 위젯 백그라운드 갱신은 로그인 토큰 없이 돌아서 관심 카테고리를 쿼리로 받는다. 예: ?categories=정치,IT */
  @GetMapping("/popular")
  public ApiResponse<List<PopularNewsResponse>> getPopular(
      @RequestParam(required = false) String categories) {
    return ApiResponse.ok(widgetService.getPopular(categories));
  }
}
