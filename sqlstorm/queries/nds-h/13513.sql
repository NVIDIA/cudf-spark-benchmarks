SELECT
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    COUNT(l_orderkey) AS line_item_count
FROM
    lineitem
WHERE
    l_shipdate >= DATE '1996-01-01'
    AND l_shipdate <= DATE '1996-12-31'
GROUP BY
    l_orderkey
ORDER BY
    total_revenue DESC
LIMIT 10;