SELECT
    p.p_brand,
    p.p_type,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    p.p_brand,
    p.p_type
ORDER BY
    total_available DESC,
    avg_supplycost ASC
LIMIT 100;
