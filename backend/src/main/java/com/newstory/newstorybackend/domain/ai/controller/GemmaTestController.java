package com.newstory.newstorybackend.domain.ai.controller;

import com.newstory.newstorybackend.domain.ai.client.GemmaApiClient;
import com.newstory.newstorybackend.global.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Profile("local")
@RestController
@RequestMapping("/api/debug/gemma")
@RequiredArgsConstructor
public class GemmaTestController {

  private final GemmaApiClient gemmaApiClient;

  @PostMapping("/test")
  public ApiResponse<String> test(
      @RequestBody String content, @RequestParam(defaultValue = "card") String style) {
    return ApiResponse.ok(gemmaApiClient.convert(content, style));
  }
}
