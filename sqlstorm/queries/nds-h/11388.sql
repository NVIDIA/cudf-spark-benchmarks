SELECT
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_supply_cost DESC
LIMIT 100;
