package com.newstory.newstorybackend.global.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import javax.crypto.SecretKey;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class JwtUtil {

  private final SecretKey secretKey;
  private final long accessExpiration;
  private final long refreshExpiration;

  public JwtUtil(
      @Value("${jwt.secret}") String secret,
      @Value("${jwt.access-expiration}") long accessExpiration,
      @Value("${jwt.refresh-expiration}") long refreshExpiration) {
    this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    this.accessExpiration = accessExpiration;
    this.refreshExpiration = refreshExpiration;
  }

  public String generateAccessToken(Long userId, String email) {
    return Jwts.builder()
        .subject(String.valueOf(userId))
        .claim("email", email)
        .claim("type", "access")
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + accessExpiration))
        .signWith(secretKey)
        .compact();
  }

  public String generateRefreshToken(Long userId) {
    return Jwts.builder()
        .subject(String.valueOf(userId))
        .claim("type", "refresh")
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + refreshExpiration))
        .signWith(secretKey)
        .compact();
  }

  public Long getUserIdFromToken(String token) {
    return Long.parseLong(getClaims(token).getSubject());
  }

  public boolean validateToken(String token) {
    try {
      getClaims(token);
      return true;
    } catch (JwtException | IllegalArgumentException e) {
      log.warn("JWT 검증 실패: {}", e.getMessage());
      return false;
    }
  }

  private Claims getClaims(String token) {
    return Jwts.parser().verifyWith(secretKey).build().parseSignedClaims(token).getPayload();
  }
}
