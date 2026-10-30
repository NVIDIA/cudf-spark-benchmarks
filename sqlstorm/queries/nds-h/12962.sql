SELECT
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS average_order_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM
    orders o
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    o.o_orderstatus;
