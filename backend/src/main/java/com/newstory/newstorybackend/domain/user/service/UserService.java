package com.newstory.newstorybackend.domain.user.service;

import com.newstory.newstorybackend.domain.user.dto.UpdateUserRequest;
import com.newstory.newstorybackend.domain.user.dto.UserResponse;
import com.newstory.newstorybackend.domain.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

  @Transactional(readOnly = true)
  public UserResponse getMe(User user) {
    return new UserResponse(user);
  }

  @Transactional
  public UserResponse updateMe(User user, UpdateUserRequest request) {
    if (request.getNickname() != null) {
      user.updateNickname(request.getNickname());
    }
    return new UserResponse(user);
  }
}
