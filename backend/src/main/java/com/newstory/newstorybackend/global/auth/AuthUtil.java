package com.newstory.newstorybackend.global.auth;

import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class AuthUtil {

  public User currentUser() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated() || !(auth.getPrincipal() instanceof User)) {
      throw new UnauthorizedException("로그인이 필요합니다.");
    }
    return (User) auth.getPrincipal();
  }
}
