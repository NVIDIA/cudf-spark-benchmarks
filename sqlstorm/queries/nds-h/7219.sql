SELECT
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    r.r_name AS region
FROM
    customer AS c
JOIN
    orders AS o ON c.c_custkey = o.o_custkey
JOIN
    lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN
    supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN
    partsupp AS ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN
    part AS p ON ps.ps_partkey = p.p_partkey
JOIN
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE
    o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    AND p.p_brand = 'Brand#23'
    AND l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
GROUP BY
    n.n_name, r.r_name
ORDER BY
    total_revenue DESC, total_orders DESC
LIMIT 10;
