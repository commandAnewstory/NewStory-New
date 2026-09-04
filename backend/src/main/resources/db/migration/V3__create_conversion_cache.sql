CREATE TABLE conversion_cache (
    id                  BIGSERIAL    PRIMARY KEY,
    article_id          BIGINT       NOT NULL REFERENCES news_articles(id),
    style               VARCHAR(20)  NOT NULL,
    converted_text      TEXT         NOT NULL,
    verification_passed BOOLEAN      NOT NULL DEFAULT FALSE,
    verification_method VARCHAR(30),
    retry_count         INTEGER      NOT NULL DEFAULT 0,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE (article_id, style)
);
