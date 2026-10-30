SELECT
    p_brand,
    AVG(ps_supplycost) AS avg_supplycost
FROM
    part
JOIN
    partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY
    p_brand
ORDER BY
    avg_supplycost DESC
LIMIT 10;
