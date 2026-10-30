SELECT
    p_brand,
    COUNT(DISTINCT ps_suppkey) AS supplier_count,
    SUM(ps_supplycost) AS total_supply_cost,
    AVG(p_retailprice) AS avg_retail_price
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    p_brand
ORDER BY
    total_supply_cost DESC
LIMIT 10;
