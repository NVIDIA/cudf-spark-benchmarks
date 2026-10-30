SELECT
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE
    o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
GROUP BY
    n.n_name, r.r_name
ORDER BY
    total_revenue DESC;