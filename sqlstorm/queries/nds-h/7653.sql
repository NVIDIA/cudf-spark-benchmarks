SELECT
    n.n_name AS nation,
    r.r_name AS region,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value
FROM
    customer c
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE
    l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    AND o.o_orderstatus = 'F'
GROUP BY
    n.n_name, r.r_name
ORDER BY
    total_revenue DESC, customer_count DESC
LIMIT 10;