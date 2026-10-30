SELECT
    p_brand,
    COUNT(*) AS supplier_count,
    AVG(ps_supplycost) AS avg_supplycost
FROM
    part AS p
JOIN
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p_brand
ORDER BY
    supplier_count DESC;
