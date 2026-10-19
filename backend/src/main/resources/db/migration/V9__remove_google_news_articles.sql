-- Google News RSS 기사는 링크가 news.google.com 리다이렉트라 본문을 못 가져와서(열면 항상 실패) 수집을 중단했다.
-- 이미 쌓인 것도 목록·위젯에서 빠지도록 지운다. 변환 결과가 붙은 기사는 보관함 보호를 위해 남긴다.
DELETE FROM article_views v
WHERE v.article_id IN (
    SELECT a.id FROM news_articles a
    WHERE a.source_type = 'google_news'
      AND NOT EXISTS (SELECT 1 FROM converted_results r WHERE r.article_id = a.id)
      AND NOT EXISTS (SELECT 1 FROM conversion_cache c WHERE c.article_id = a.id));

DELETE FROM news_articles a
WHERE a.source_type = 'google_news'
  AND NOT EXISTS (SELECT 1 FROM converted_results r WHERE r.article_id = a.id)
  AND NOT EXISTS (SELECT 1 FROM conversion_cache c WHERE c.article_id = a.id)
  AND NOT EXISTS (SELECT 1 FROM article_views v WHERE v.article_id = a.id);
