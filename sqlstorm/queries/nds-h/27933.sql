SELECT
    CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_info,
    s.s_name AS supplier_name,
    CONCAT('Customer: ', c.c_name, ', Nation: ', n.n_name) AS customer_info,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order
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
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
WHERE
    p.p_brand NOT LIKE 'Brand%'
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND l.l_returnflag = 'N'
GROUP BY
    p.p_name, p.p_brand, p.p_type, s.s_name, c.c_name, n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;