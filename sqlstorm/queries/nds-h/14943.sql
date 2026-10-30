SELECT
    l_partkey,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    p_brand,
    p_type,
    p_size
FROM
    lineitem
JOIN
    part ON l_partkey = p_partkey
WHERE
    l_shipdate >= DATE '1996-01-01'
    AND l_shipdate < DATE '1996-12-31'
GROUP BY
    l_partkey, p_brand, p_type, p_size
ORDER BY
    revenue DESC
LIMIT 10;
