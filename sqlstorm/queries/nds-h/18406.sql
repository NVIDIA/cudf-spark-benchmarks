SELECT p_brand, COUNT(*) AS brand_count
FROM part
GROUP BY p_brand
ORDER BY brand_count DESC;
