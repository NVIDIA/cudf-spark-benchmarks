SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    customer c ON c.c_custkey = s.s_nationkey
JOIN
    orders o ON o.o_custkey = c.c_custkey
WHERE
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    revenue DESC
LIMIT 10;