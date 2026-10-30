SELECT
    p.p_name,
    s.s_name,
    l.l_quantity,
    l.l_extendedprice,
    o.o_orderdate
FROM
    lineitem l
JOIN
    part p ON l.l_partkey = p.p_partkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
ORDER BY
    l.l_extendedprice DESC
LIMIT 100;