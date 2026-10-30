SELECT
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    c.c_name,
    n.n_name,
    r.r_name
FROM
    orders o
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    o.o_orderdate >= DATE '1995-01-01'
    AND o.o_orderdate < DATE '1995-02-01'
GROUP BY
    o.o_orderkey,
    c.c_name,
    n.n_name,
    r.r_name
ORDER BY
    revenue DESC;