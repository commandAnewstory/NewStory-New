package com.newstory.newstorybackend.domain.auth.controller;

import com.newstory.newstorybackend.domain.auth.dto.LoginRequest;
import com.newstory.newstorybackend.domain.auth.dto.LoginResponse;
import com.newstory.newstorybackend.domain.auth.dto.RefreshRequest;
import com.newstory.newstorybackend.domain.auth.dto.SignupRequest;
import com.newstory.newstorybackend.domain.auth.dto.TokenResponse;
import com.newstory.newstorybackend.domain.auth.service.AuthService;
import com.newstory.newstorybackend.global.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

  private final AuthService authService;

  @PostMapping("/signup")
  @ResponseStatus(HttpStatus.CREATED)
  public ApiResponse<Void> signup(@Valid @RequestBody SignupRequest request) {
    authService.signup(request);
    return ApiResponse.ok();
  }

  @PostMapping("/login")
  public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
    return ApiResponse.ok(authService.login(request));
  }

  @PostMapping("/logout")
  public ApiResponse<Void> logout(@Valid @RequestBody RefreshRequest request) {
    authService.logout(request.getRefreshToken());
    return ApiResponse.ok();
  }

  @PostMapping("/refresh")
  public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
    return ApiResponse.ok(authService.refresh(request));
  }
}
