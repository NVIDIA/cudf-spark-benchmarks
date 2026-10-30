SELECT p_mfgr, COUNT(*) AS part_count
FROM part
GROUP BY p_mfgr
ORDER BY part_count DESC
LIMIT 10;
