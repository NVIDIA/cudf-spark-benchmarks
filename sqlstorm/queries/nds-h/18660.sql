SELECT p_type, COUNT(*) AS part_count
FROM part
GROUP BY p_type
ORDER BY part_count DESC;
