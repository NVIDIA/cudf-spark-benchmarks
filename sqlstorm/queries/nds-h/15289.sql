SELECT p_brand, COUNT(*) as brand_count
FROM part
GROUP BY p_brand
ORDER BY brand_count DESC
LIMIT 10;
