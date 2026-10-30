SELECT
    l_shipmode,
    COUNT(*) AS num_orders,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_discount) AS avg_discount
FROM
    lineitem
WHERE
    l_shipdate >= DATE '1997-01-01'
    AND l_shipdate < DATE '1997-12-31'
GROUP BY
    l_shipmode
ORDER BY
    total_revenue DESC;