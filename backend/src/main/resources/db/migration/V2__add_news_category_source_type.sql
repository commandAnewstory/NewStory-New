ALTER TABLE news_articles ADD COLUMN category    VARCHAR(30);
ALTER TABLE news_articles ADD COLUMN source_type VARCHAR(20) NOT NULL DEFAULT 'rss';
