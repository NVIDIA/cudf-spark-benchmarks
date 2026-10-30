SELECT
    CONCAT_WS(' ', c.c_name, 'from', n.n_name, '(', r.r_name, ')') AS customer_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    (SELECT COUNT(*) FROM part p WHERE p.p_comment LIKE '%green%') AS green_parts_count,
    (SELECT COUNT(*) FROM supplier s WHERE s.s_comment LIKE '%urgent%') AS urgent_suppliers_count
FROM
    customer c
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY
    c.c_name, n.n_name, r.r_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY
    total_revenue DESC
LIMIT 10;
