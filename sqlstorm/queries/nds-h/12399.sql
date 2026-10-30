SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderpriority
FROM
    lineitem
JOIN
    orders ON l_orderkey = o_orderkey
WHERE
    l_shipdate >= '1996-01-01' AND l_shipdate < '1997-01-01'
GROUP BY
    o_orderpriority
ORDER BY
    total_revenue DESC;