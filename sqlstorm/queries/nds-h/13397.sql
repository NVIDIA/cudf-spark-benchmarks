SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    customer c ON l.l_orderkey = c.c_custkey
WHERE
    s.s_acctbal > 5000
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_revenue DESC
LIMIT 10;
