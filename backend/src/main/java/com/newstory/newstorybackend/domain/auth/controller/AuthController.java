package com.newstory.newstorybackend.domain.auth.controller;

import com.newstory.newstorybackend.domain.auth.dto.LoginRequest;
import com.newstory.newstorybackend.domain.auth.dto.LoginResponse;
import com.newstory.newstorybackend.domain.auth.dto.RefreshRequest;
import com.newstory.newstorybackend.domain.auth.dto.SignupRequest;
import com.newstory.newstorybackend.domain.auth.dto.SocialLoginRequest;
import com.newstory.newstorybackend.domain.auth.dto.SocialUserInfo;
import com.newstory.newstorybackend.domain.auth.dto.TokenResponse;
import com.newstory.newstorybackend.domain.auth.service.AuthService;
import com.newstory.newstorybackend.domain.auth.service.GoogleAuthService;
import com.newstory.newstorybackend.domain.auth.service.KakaoAuthService;
import com.newstory.newstorybackend.global.common.ApiResponse;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
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
  private final KakaoAuthService kakaoAuthService;
  private final GoogleAuthService googleAuthService;

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

  @PostMapping("/social/{provider}")
  public ApiResponse<LoginResponse> socialLogin(
      @PathVariable String provider, @Valid @RequestBody SocialLoginRequest request) {
    SocialUserInfo info =
        switch (provider) {
          case "kakao" -> kakaoAuthService.getUserInfo(request.getToken());
          case "google" -> googleAuthService.getUserInfo(request.getToken());
          default -> throw new NotFoundException("지원하지 않는 소셜 로그인 provider: " + provider);
        };
    return ApiResponse.ok(authService.socialLogin(info));
  }
}
