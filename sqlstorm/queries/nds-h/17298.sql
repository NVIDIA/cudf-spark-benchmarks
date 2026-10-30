SELECT p_brand, COUNT(*) AS total_parts
FROM part
WHERE p_retailprice > 50.00
GROUP BY p_brand
ORDER BY total_parts DESC;
