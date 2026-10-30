SELECT
    p.p_name,
    s.s_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    l.l_quantity,
    l.l_extendedprice
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
WHERE
    l.l_shipdate >= '1997-01-01'
ORDER BY
    ps.ps_supplycost DESC
LIMIT 10;