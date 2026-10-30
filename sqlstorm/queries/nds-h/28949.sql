SELECT
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_extendedprice) AS avg_price_per_item,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(l.l_discount) AS max_discount
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    s.s_comment LIKE '%quality%' AND
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY
    total_revenue DESC;