SELECT
    p_brand,
    COUNT(*) AS supply_count,
    AVG(ps_supplycost) AS avg_supply_cost
FROM
    part
JOIN
    partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
GROUP BY
    p_brand
ORDER BY
    supply_count DESC;
