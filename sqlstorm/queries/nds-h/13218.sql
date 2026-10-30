SELECT
    l_shipmode,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    COUNT(DISTINCT o_orderkey) AS order_count
FROM
    lineitem
JOIN
    orders ON l_orderkey = o_orderkey
WHERE
    l_shipdate >= '1997-01-01'
    AND l_shipdate < '1998-01-01'
GROUP BY
    l_shipmode
ORDER BY
    revenue DESC;