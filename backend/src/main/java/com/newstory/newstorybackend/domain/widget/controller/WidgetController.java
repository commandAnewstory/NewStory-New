package com.newstory.newstorybackend.domain.widget.controller;

import com.newstory.newstorybackend.domain.widget.dto.TodayCardResponse;
import com.newstory.newstorybackend.domain.widget.service.WidgetService;
import com.newstory.newstorybackend.global.common.ApiResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
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
}
