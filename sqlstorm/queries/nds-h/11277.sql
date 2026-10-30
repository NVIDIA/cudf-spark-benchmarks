SELECT
    l_shipmode,
    SUM(l_quantity) AS total_quantity,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    AVG(o_totalprice) AS average_price
FROM
    lineitem
JOIN
    orders ON l_orderkey = o_orderkey
WHERE
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    l_shipmode
ORDER BY
    total_quantity DESC;