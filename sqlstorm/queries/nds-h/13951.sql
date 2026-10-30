SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    p_brand,
    p_type,
    p_size,
    o_orderdate
FROM
    lineitem
JOIN
    part ON l_partkey = p_partkey
JOIN
    orders ON l_orderkey = o_orderkey
GROUP BY
    p_brand, p_type, p_size, o_orderdate
ORDER BY
    revenue DESC
LIMIT 10;
