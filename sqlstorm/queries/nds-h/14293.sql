SELECT
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE
    o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1997-12-31'
GROUP BY
    c.c_name, o.o_orderkey
ORDER BY
    total_revenue DESC
LIMIT 100;