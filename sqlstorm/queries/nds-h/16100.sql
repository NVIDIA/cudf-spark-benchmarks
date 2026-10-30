SELECT
    p_brand,
    COUNT(*) AS part_count,
    AVG(p_retailprice) AS avg_price
FROM
    part
GROUP BY
    p_brand
ORDER BY
    part_count DESC
LIMIT 10;
