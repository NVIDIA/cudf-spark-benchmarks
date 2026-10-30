SELECT
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-10-01'
GROUP BY
    n.n_name, r.r_name
ORDER BY
    total_revenue DESC, avg_order_value DESC
LIMIT 100;