SELECT
    p_brand,
    AVG(l_extendedprice * (1 - l_discount)) AS avg_price,
    SUM(l_quantity) AS total_quantity,
    COUNT(DISTINCT o_orderkey) AS total_orders
FROM
    part
JOIN
    lineitem ON p_partkey = l_partkey
JOIN
    orders ON l_orderkey = o_orderkey
GROUP BY
    p_brand
ORDER BY
    avg_price DESC
LIMIT 10;
