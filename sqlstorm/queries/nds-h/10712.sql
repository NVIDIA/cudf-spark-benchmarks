SELECT
    l_shipmode,
    COUNT(l_orderkey) AS order_count,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_discount) AS average_discount,
    SUM(l_tax) AS total_tax
FROM
    lineitem
WHERE
    l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY
    l_shipmode
ORDER BY
    total_revenue DESC;