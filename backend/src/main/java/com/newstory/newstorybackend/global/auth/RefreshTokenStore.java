package com.newstory.newstorybackend.global.auth;

import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

@Component
public class RefreshTokenStore {

  private final ConcurrentHashMap<String, Long> store = new ConcurrentHashMap<>();

  public void save(String refreshToken, Long userId) {
    store.put(refreshToken, userId);
  }

  public Long getUserId(String refreshToken) {
    return store.get(refreshToken);
  }

  public void delete(String refreshToken) {
    store.remove(refreshToken);
  }

  public boolean exists(String refreshToken) {
    return store.containsKey(refreshToken);
  }
}
