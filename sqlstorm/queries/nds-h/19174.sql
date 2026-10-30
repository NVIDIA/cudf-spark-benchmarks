SELECT p_brand, COUNT(*) AS product_count
FROM part
GROUP BY p_brand
ORDER BY product_count DESC
LIMIT 10;
