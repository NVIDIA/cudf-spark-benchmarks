SELECT
    p.p_brand,
    p.p_type,
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_revenue
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem ON p.p_partkey = lineitem.l_partkey
JOIN
    orders o ON lineitem.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name = 'ASIA'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_brand, p.p_type
ORDER BY
    total_revenue DESC
LIMIT 10;