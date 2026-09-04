package com.newstory.newstorybackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class NewstorybackendApplication {

  public static void main(String[] args) {
    SpringApplication.run(NewstorybackendApplication.class, args);
  }
}
