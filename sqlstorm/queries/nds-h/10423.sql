SELECT
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue_after_discount
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
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
GROUP BY
    r.r_name, n.n_name
ORDER BY
    r.r_name, n.n_name;
