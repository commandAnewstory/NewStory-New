package com.newstory.newstorybackend.domain.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class LoginResponse {

  private final String accessToken;
  private final String refreshToken;
  private final String nickname;
}
