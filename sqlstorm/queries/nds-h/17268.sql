SELECT p_brand, COUNT(*) as total_parts
FROM part
GROUP BY p_brand
ORDER BY total_parts DESC
LIMIT 10;
