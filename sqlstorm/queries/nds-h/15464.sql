SELECT p_brand, COUNT(*) AS num_parts
FROM part
GROUP BY p_brand
ORDER BY num_parts DESC
LIMIT 10;
