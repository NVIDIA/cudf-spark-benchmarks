SELECT
    p.p_brand,
    p.p_type,
    p.p_size,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p.p_brand,
    p.p_type,
    p.p_size
ORDER BY
    total_available_quantity DESC
LIMIT 100;
