SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
GROUP BY
    p.p_partkey, p.p_name, o.o_orderdate
ORDER BY
    revenue DESC
LIMIT 100;
