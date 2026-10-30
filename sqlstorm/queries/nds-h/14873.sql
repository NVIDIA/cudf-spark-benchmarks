SELECT
    l.l_shipmode,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1997-12-31'
GROUP BY
    l.l_shipmode
ORDER BY
    total_revenue DESC;