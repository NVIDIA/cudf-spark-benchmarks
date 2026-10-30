SELECT
    p.p_name,
    s.s_name,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS finished_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_name LIKE 'Widget%'
    AND s.s_comment NOT LIKE '%Fragile%'
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    p.p_name,
    s.s_name,
    n.n_name
ORDER BY
    avg_revenue DESC,
    customer_count DESC;