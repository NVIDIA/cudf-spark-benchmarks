SELECT
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    COUNT(li.l_orderkey) AS total_line_items,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Customer: ', c.c_name, ' | Order ID: ', o.o_orderkey) AS detailed_info
FROM
    lineitem li
JOIN
    orders o ON li.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON li.l_partkey = p.p_partkey
WHERE
    li.l_shipdate >= '1997-01-01'
    AND li.l_shipdate < '1997-12-31'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
ORDER BY
    total_revenue DESC
LIMIT 10;