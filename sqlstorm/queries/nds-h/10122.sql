SELECT
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_quantity) AS avg_lineitem_quantity,
    MAX(ps.ps_supplycost) AS max_supply_cost
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
GROUP BY
    c.c_nationkey
ORDER BY
    total_revenue DESC;
