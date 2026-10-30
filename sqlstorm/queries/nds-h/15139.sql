SELECT p_brand, COUNT(*) AS number_of_parts
FROM part
GROUP BY p_brand
ORDER BY number_of_parts DESC
LIMIT 10;
