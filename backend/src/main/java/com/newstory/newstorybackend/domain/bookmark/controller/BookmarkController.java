package com.newstory.newstorybackend.domain.bookmark.controller;

import com.newstory.newstorybackend.domain.bookmark.dto.BookmarkResponse;
import com.newstory.newstorybackend.domain.bookmark.service.BookmarkService;
import com.newstory.newstorybackend.global.auth.AuthUtil;
import com.newstory.newstorybackend.global.common.ApiResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/bookmarks")
@RequiredArgsConstructor
public class BookmarkController {

  private final BookmarkService bookmarkService;
  private final AuthUtil authUtil;

  @GetMapping
  public ApiResponse<List<BookmarkResponse>> getBookmarks() {
    return ApiResponse.ok(bookmarkService.getBookmarks(authUtil.currentUser().getId()));
  }

  @PostMapping("/{resultId}")
  @ResponseStatus(HttpStatus.CREATED)
  public ApiResponse<Void> addBookmark(@PathVariable Long resultId) {
    bookmarkService.addBookmark(resultId, authUtil.currentUser());
    return ApiResponse.ok();
  }

  @DeleteMapping("/{resultId}")
  public ApiResponse<Void> removeBookmark(@PathVariable Long resultId) {
    bookmarkService.removeBookmark(resultId, authUtil.currentUser().getId());
    return ApiResponse.ok();
  }
}
