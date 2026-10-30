
SELECT
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', n.n_name) AS supplier_customer_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order
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
WHERE
    c.c_acctbal > 1000
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY
    c.c_name, s.s_name, n.n_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    total_revenue DESC;
