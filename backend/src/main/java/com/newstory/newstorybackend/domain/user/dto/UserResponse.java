package com.newstory.newstorybackend.domain.user.dto;

import com.newstory.newstorybackend.domain.user.entity.User;
import lombok.Getter;

@Getter
public class UserResponse {

  private final Long id;
  private final String email;
  private final String nickname;

  public UserResponse(User user) {
    this.id = user.getId();
    this.email = user.getEmail();
    this.nickname = user.getNickname();
  }
}
