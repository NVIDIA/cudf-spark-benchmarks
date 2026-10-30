SELECT
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM
    nation n
JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1996-12-31'
    AND l.l_shipmode IN ('TRUCK', 'AIR')
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;