SELECT
    p.p_partkey,
    p.p_name,
    s.s_name,
    ps.ps_supplycost,
    l.l_quantity,
    o.o_orderdate,
    c.c_name
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
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
ORDER BY
    p.p_partkey, o.o_orderdate DESC;