SELECT
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
WHERE
    o.o_orderdate >= DATE '1995-01-01'
    AND o.o_orderdate < DATE '1996-01-01'
GROUP BY
    p.p_name, o.o_orderdate
ORDER BY
    revenue DESC;
