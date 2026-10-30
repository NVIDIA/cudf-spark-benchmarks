SELECT
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    n.n_name AS nation
FROM
    orders o
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;
