SELECT
    p.p_brand,
    p.p_type,
    p.p_size,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY
    p.p_brand, p.p_type, p.p_size
ORDER BY
    total_extended_price DESC
LIMIT 100;
