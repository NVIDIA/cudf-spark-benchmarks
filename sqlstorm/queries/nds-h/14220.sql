SELECT
    p.p_partkey,
    p.p_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax
FROM
    part AS p
JOIN
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN
    customer AS c ON o.o_custkey = c.c_custkey
WHERE
    c.c_acctbal > 10000
ORDER BY
    l.l_extendedprice DESC
LIMIT 100;
