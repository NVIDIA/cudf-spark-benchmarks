SELECT p_brand, COUNT(*) as part_count
FROM part
GROUP BY p_brand
ORDER BY part_count DESC;
