SELECT
    l_shipmode,
    SUM(CASE
        WHEN l_returnflag = 'R' THEN l_extendedprice * (1 - l_discount)
        ELSE 0
    END) AS total_revenue,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    COUNT(DISTINCT l_suppkey) AS total_suppliers
FROM
    lineitem
JOIN
    orders ON l_orderkey = o_orderkey
WHERE
    l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1997-12-31'
GROUP BY
    l_shipmode
ORDER BY
    l_shipmode;