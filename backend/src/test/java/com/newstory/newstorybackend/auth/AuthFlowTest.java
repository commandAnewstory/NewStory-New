package com.newstory.newstorybackend.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.newstory.newstorybackend.support.IntegrationTestSupport;
import java.util.Map;
import org.junit.jupiter.api.Test;

class AuthFlowTest extends IntegrationTestSupport {

  @Test
  void 회원가입_로그인_후_내정보를_조회한다() {
    Tokens tokens = signupAndLogin("auth1@newstory.test");

    Res me = get("/api/users/me", tokens.accessToken());

    assertThat(me.status()).isEqualTo(200);
    assertThat((String) me.json("$.data.email")).isEqualTo("auth1@newstory.test");
    assertThat((String) me.json("$.data.lastGlossaryLevel")).isEqualTo("MEDIUM");
    assertThat((Boolean) me.json("$.data.widgetEnabled")).isFalse();
  }

  @Test
  void 같은_이메일로_다시_가입하면_409() {
    signupAndLogin("dup@newstory.test");

    Res again =
        post(
            "/api/auth/signup",
            Map.of("email", "dup@newstory.test", "password", "password1234", "nickname", "x"),
            null);

    assertThat(again.status()).isEqualTo(409);
    assertThat((String) again.json("$.message")).isEqualTo("이미 사용 중인 이메일입니다.");
  }

  @Test
  void 비밀번호가_틀리면_401() {
    signupAndLogin("wrongpw@newstory.test");

    Res login =
        post(
            "/api/auth/login",
            Map.of("email", "wrongpw@newstory.test", "password", "not-the-password"),
            null);

    assertThat(login.status()).isEqualTo(401);
  }

  @Test
  void 토큰_없이_보호된_API를_부르면_401() {
    assertThat(get("/api/users/me", null).status()).isEqualTo(401);
  }

  @Test
  void 로그아웃한_refresh_토큰으로는_재발급이_안된다() {
    Tokens tokens = signupAndLogin("logout@newstory.test");
    Map<String, String> body = Map.of("refreshToken", tokens.refreshToken());

    Res refreshBefore = post("/api/auth/refresh", body, null);
    assertThat(refreshBefore.status()).isEqualTo(200);

    Res logout = post("/api/auth/logout", body, null);
    assertThat(logout.status()).isEqualTo(200);

    Res refreshAfter = post("/api/auth/refresh", body, null);
    assertThat(refreshAfter.status()).isEqualTo(401);
  }

  @Test
  void 위젯_설정을_바꾸면_다시_조회해도_유지된다() {
    Tokens tokens = signupAndLogin("widget@newstory.test");

    Res patch = patch("/api/users/me", Map.of("widgetEnabled", true), tokens.accessToken());
    assertThat(patch.status()).isEqualTo(200);

    Res me = get("/api/users/me", tokens.accessToken());
    assertThat((Boolean) me.json("$.data.widgetEnabled")).isTrue();
  }
}
