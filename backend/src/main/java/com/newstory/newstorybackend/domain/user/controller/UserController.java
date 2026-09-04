package com.newstory.newstorybackend.domain.user.controller;

import com.newstory.newstorybackend.domain.user.dto.UpdateUserRequest;
import com.newstory.newstorybackend.domain.user.dto.UserResponse;
import com.newstory.newstorybackend.domain.user.service.UserService;
import com.newstory.newstorybackend.global.auth.AuthUtil;
import com.newstory.newstorybackend.global.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

  private final UserService userService;
  private final AuthUtil authUtil;

  @GetMapping("/me")
  public ApiResponse<UserResponse> getMe() {
    return ApiResponse.ok(userService.getMe(authUtil.currentUser()));
  }

  @PatchMapping("/me")
  public ApiResponse<UserResponse> updateMe(@Valid @RequestBody UpdateUserRequest request) {
    return ApiResponse.ok(userService.updateMe(authUtil.currentUser(), request));
  }
}
