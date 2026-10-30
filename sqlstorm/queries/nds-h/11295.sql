SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderstatus = 'F'
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_sales DESC
LIMIT 10;
