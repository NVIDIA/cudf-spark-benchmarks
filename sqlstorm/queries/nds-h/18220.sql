SELECT p_brand, COUNT(*) AS part_count 
FROM part 
GROUP BY p_brand 
ORDER BY part_count DESC;
