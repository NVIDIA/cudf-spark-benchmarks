SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderstatus = 'O'
GROUP BY
    p.p_partkey, p.p_name, p.p_brand
ORDER BY
    total_quantity DESC
LIMIT 10;
