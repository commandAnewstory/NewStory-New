CREATE TABLE users (
    id         BIGSERIAL PRIMARY KEY,
    email      VARCHAR(255) NOT NULL UNIQUE,
    password   VARCHAR(255),
    nickname   VARCHAR(50)  NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE news_articles (
    id           BIGSERIAL PRIMARY KEY,
    url          TEXT         NOT NULL UNIQUE,
    title        VARCHAR(500) NOT NULL,
    description  TEXT,
    source       VARCHAR(100),
    published_at TIMESTAMP,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE article_views (
    id         BIGSERIAL PRIMARY KEY,
    article_id BIGINT    NOT NULL REFERENCES news_articles (id),
    user_id    BIGINT    REFERENCES users (id),
    viewed_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE converted_results (
    id                  BIGSERIAL PRIMARY KEY,
    article_id          BIGINT       NOT NULL REFERENCES news_articles (id),
    user_id             BIGINT       REFERENCES users (id),
    style               VARCHAR(20)  NOT NULL,
    converted_text      TEXT         NOT NULL,
    verification_passed BOOLEAN      NOT NULL DEFAULT FALSE,
    verification_method VARCHAR(30),
    retry_count         INTEGER      NOT NULL DEFAULT 0,
    is_feed             BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE bookmarks (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT    NOT NULL REFERENCES users (id),
    result_id  BIGINT    NOT NULL REFERENCES converted_results (id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, result_id)
);
