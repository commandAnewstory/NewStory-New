package com.newstory.newstorybackend.domain.convert.controller;

import com.newstory.newstorybackend.domain.convert.dto.ConvertRequest;
import com.newstory.newstorybackend.domain.convert.dto.ConvertResponse;
import com.newstory.newstorybackend.domain.convert.dto.OriginalArticleResponse;
import com.newstory.newstorybackend.domain.convert.service.ConvertService;
import com.newstory.newstorybackend.global.auth.AuthUtil;
import com.newstory.newstorybackend.global.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/convert")
@RequiredArgsConstructor
public class ConvertController {

  private final ConvertService convertService;
  private final AuthUtil authUtil;

  @GetMapping("/original")
  public ApiResponse<OriginalArticleResponse> getOriginal(@RequestParam String url) {
    return ApiResponse.ok(convertService.getOriginal(url));
  }

  @PostMapping
  public ApiResponse<ConvertResponse> convert(@Valid @RequestBody ConvertRequest request) {
    return ApiResponse.ok(convertService.convert(request, authUtil.currentUser()));
  }

  @GetMapping("/{resultId}")
  public ApiResponse<ConvertResponse> getResult(@PathVariable Long resultId) {
    return ApiResponse.ok(convertService.getResult(resultId, authUtil.currentUser()));
  }
}
