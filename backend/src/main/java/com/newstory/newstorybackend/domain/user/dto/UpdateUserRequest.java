package com.newstory.newstorybackend.domain.user.dto;

import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class UpdateUserRequest {

  @Size(min = 1, max = 50)
  private String nickname;
}
