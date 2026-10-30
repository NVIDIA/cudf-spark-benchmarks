SELECT
    l_shipmode,
    COUNT(*) AS total_orders,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_quantity) AS average_quantity
FROM
    lineitem
WHERE
    l_shipdate >= '1997-01-01'
GROUP BY
    l_shipmode
ORDER BY
    total_revenue DESC;