SELECT
    s.s_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderstatus = 'F'
GROUP BY
    s.s_name
ORDER BY
    total_supply_cost DESC
LIMIT 10;
