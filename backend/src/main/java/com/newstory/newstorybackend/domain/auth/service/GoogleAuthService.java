package com.newstory.newstorybackend.domain.auth.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.newstory.newstorybackend.domain.auth.dto.SocialUserInfo;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Service
public class GoogleAuthService {

  private static final String TOKEN_INFO_URL = "https://oauth2.googleapis.com/tokeninfo?id_token=";
  private static final String PROVIDER = "google";

  private final List<String> allowedClientIds;
  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper = new ObjectMapper();

  public GoogleAuthService(
      @Value("${google.client-id.android}") String androidClientId,
      @Value("${google.client-id.ios}") String iosClientId,
      @Value("${google.client-id.web}") String webClientId,
      RestTemplate restTemplate) {
    this.allowedClientIds = List.of(androidClientId, iosClientId, webClientId);
    this.restTemplate = restTemplate;
  }

  public SocialUserInfo getUserInfo(String idToken) {
    try {
      String response = restTemplate.getForObject(TOKEN_INFO_URL + idToken, String.class);
      JsonNode root = objectMapper.readTree(response);

      String aud = root.path("aud").asText();
      if (allowedClientIds.stream().noneMatch(aud::equals)) {
        throw new UnauthorizedException("유효하지 않은 Google 토큰입니다.");
      }

      String providerId = root.path("sub").asText();
      String email = root.path("email").asText();

      return new SocialUserInfo(PROVIDER, providerId, email);
    } catch (UnauthorizedException e) {
      throw e;
    } catch (Exception e) {
      log.error("Google 사용자 정보 조회 실패: {}", e.getMessage());
      throw new UnauthorizedException("유효하지 않은 Google 토큰입니다.");
    }
  }
}
