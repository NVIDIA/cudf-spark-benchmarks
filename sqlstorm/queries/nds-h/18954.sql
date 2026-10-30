SELECT
    p.p_partkey,
    p.p_name,
    s.s_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    p.p_partkey, p.p_name, s.s_name
ORDER BY
    total_supply_cost DESC;
