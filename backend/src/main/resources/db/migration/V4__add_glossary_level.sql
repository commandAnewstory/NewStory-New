-- 용어 글로서리 난이도 레벨 (2026-09-04 결정, docs/01-decisions/2026-09-04-glossary-level.md 참고)

ALTER TABLE users
    ADD COLUMN last_glossary_level VARCHAR(10) NOT NULL DEFAULT 'MEDIUM';

ALTER TABLE conversion_cache
    ADD COLUMN level VARCHAR(10) NOT NULL DEFAULT 'MEDIUM';

ALTER TABLE conversion_cache
    DROP CONSTRAINT conversion_cache_article_id_style_key;

ALTER TABLE conversion_cache
    ADD CONSTRAINT conversion_cache_article_id_style_level_key UNIQUE (article_id, style, level);
