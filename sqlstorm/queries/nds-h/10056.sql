SELECT
    p.p_partkey,
    p.p_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    s.s_name,
    s.s_acctbal,
    o.o_orderkey,
    o.o_totalprice,
    c.c_name,
    c.c_mktsegment
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
    p.p_retailprice > 100.00
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY
    o.o_orderkey ASC;