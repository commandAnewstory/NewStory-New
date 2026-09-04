package com.newstory.newstorybackend.domain.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class User {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, unique = true, length = 255)
  private String email;

  @Column(length = 255)
  private String password;

  @Column(nullable = false, length = 50)
  private String nickname;

  @Column(nullable = false, length = 20)
  @Builder.Default
  private String provider = "email";

  @Column(name = "provider_id", length = 255)
  private String providerId;

  @Column(name = "widget_enabled", nullable = false)
  @Builder.Default
  private Boolean widgetEnabled = false;

  @Column(name = "last_glossary_level", nullable = false, length = 10)
  @Builder.Default
  private String lastGlossaryLevel = "MEDIUM";

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;

  public void updateNickname(String nickname) {
    this.nickname = nickname;
  }

  public void updatePassword(String encodedPassword) {
    this.password = encodedPassword;
  }

  public void updateLastGlossaryLevel(String level) {
    this.lastGlossaryLevel = level;
  }

  public void updateWidgetEnabled(boolean enabled) {
    this.widgetEnabled = enabled;
  }
}
