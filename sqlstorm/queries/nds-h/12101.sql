SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice) AS total_sales,
    COUNT(l.l_orderkey) AS number_of_orders
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_partkey,
    p.p_name
ORDER BY
    total_sales DESC
LIMIT 10;