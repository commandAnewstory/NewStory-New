package com.newstory.newstorybackend.domain.ai.client;

import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Component
public class GemmaApiClient {

  private final String apiUrl;
  private final RestTemplate restTemplate;

  public GemmaApiClient(@Value("${gemma.api-url}") String apiUrl, RestTemplate restTemplate) {
    this.apiUrl = apiUrl;
    this.restTemplate = restTemplate;
  }

  public String convert(String content, String style, String level) {
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);

    Map<String, String> body = Map.of("content", content, "style", style, "level", level);
    HttpEntity<Map<String, String>> entity = new HttpEntity<>(body, headers);

    String response = restTemplate.postForObject(apiUrl, entity, String.class);
    log.debug("Gemma 응답 수신 (style={}, level={})", style, level);
    return response;
  }
}
