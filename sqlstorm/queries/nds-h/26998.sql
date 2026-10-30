SELECT
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(o.o_totalprice) AS average_order_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM
    part AS p
JOIN
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN
    customer AS c ON o.o_custkey = c.c_custkey
WHERE
    s.s_comment LIKE '%urgent%'
    AND p.p_type LIKE '%metal%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY
    p.p_name, s.s_name
HAVING
    SUM(ps.ps_availqty) > 100
ORDER BY
    total_available_quantity DESC, average_order_price ASC;