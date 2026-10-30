SELECT p_brand, COUNT(*) AS parts_count
FROM part
GROUP BY p_brand
ORDER BY parts_count DESC
LIMIT 10;
