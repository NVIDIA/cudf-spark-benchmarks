SELECT
    p.p_partkey,
    p.p_name,
    s.s_suppkey,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY
    p.p_partkey, p.p_name, s.s_suppkey, s.s_name
ORDER BY
    total_available_qty DESC;
