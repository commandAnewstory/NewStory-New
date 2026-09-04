package com.newstory.newstorybackend.domain.history.controller;

import com.newstory.newstorybackend.domain.history.dto.HistoryResponse;
import com.newstory.newstorybackend.domain.history.service.HistoryService;
import com.newstory.newstorybackend.global.auth.AuthUtil;
import com.newstory.newstorybackend.global.common.ApiResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/history")
@RequiredArgsConstructor
public class HistoryController {

  private final HistoryService historyService;
  private final AuthUtil authUtil;

  @GetMapping
  public ApiResponse<List<HistoryResponse>> getHistory() {
    return ApiResponse.ok(historyService.getHistory(authUtil.currentUser().getId()));
  }

  @DeleteMapping("/{resultId}")
  public ApiResponse<Void> delete(@PathVariable Long resultId) {
    historyService.delete(resultId, authUtil.currentUser().getId());
    return ApiResponse.ok();
  }
}
