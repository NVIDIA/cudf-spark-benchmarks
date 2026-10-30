SELECT
    p_brand,
    AVG(ps_supplycost) AS avg_supplycost
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p_brand
ORDER BY
    avg_supplycost DESC
LIMIT 10;
