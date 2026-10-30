SELECT
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_brand AS brand,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    part p ON l.l_partkey = p.p_partkey
WHERE
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND l.l_shipmode IN ('AIR', 'SHIP')
GROUP BY
    c.c_name, n.n_name, s.s_name, p.p_name, p.p_brand
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY
    total_revenue DESC,
    nation_name ASC;