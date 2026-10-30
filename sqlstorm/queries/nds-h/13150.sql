SELECT
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    c.c_name,
    o.o_orderdate
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    l.l_shipdate >= '1994-01-01' AND l.l_shipdate < '1995-01-01'
GROUP BY
    p.p_name, c.c_name, o.o_orderdate
ORDER BY
    revenue DESC
LIMIT 10;
