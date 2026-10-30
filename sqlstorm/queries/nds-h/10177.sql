SELECT
    p.p_mfgr,
    SUM(ps.ps_availqty) AS total_availqty,
    AVG(l.l_extendedprice) AS avg_extendedprice,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY
    p.p_mfgr
ORDER BY
    total_availqty DESC
LIMIT 10;
