SELECT
    p.p_partkey,
    p.p_name,
    s.s_name,
    ps.ps_supplycost,
    l.l_extendedprice,
    o.o_orderdate
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY
    ps.ps_supplycost DESC
LIMIT 100;